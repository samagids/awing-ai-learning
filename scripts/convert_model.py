"""
convert_model.py
Converts a HuggingFace sentence-transformers model to TFLite format
for on-device inference in the Awing AI Learning app.

Pipeline: HuggingFace model -> TF Keras (from_pt=True) -> TFLite

This approach bypasses ONNX entirely, avoiding onnx2tf dimension
transposition bugs that break transformer/NLP models.

Required packages (install in venv):
    pip install -r scripts\\requirements.txt

Broken approaches that this script avoids:
    - torch.onnx.export: fails with transformers v5+ attention masking
    - onnx2tf: transposes NLP tensor dims as if they were image NCHW
    - ai-edge-torch: requires torch_xla (Linux-only)
    - onnx-tf: deprecated
"""

import os
import sys
from pathlib import Path

SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))

# Auto-activate venv_tf (TensorFlow env for model conversion)
VENV_DIR = SCRIPT_DIR.parent / "venv_tf"
if not VENV_DIR.exists():
    VENV_DIR = SCRIPT_DIR.parent / "venv"  # fallback to old single-venv name
if VENV_DIR.exists() and sys.prefix == sys.base_prefix:
    import subprocess
    if sys.platform == "win32":
        venv_python = str(VENV_DIR / "Scripts" / "python.exe")
    else:
        venv_python = str(VENV_DIR / "bin" / "python")
    if os.path.exists(venv_python) and os.path.abspath(venv_python) != os.path.abspath(sys.executable):
        print("  Auto-activating virtual environment...")
        result = subprocess.run([venv_python] + sys.argv)
        sys.exit(result.returncode)

MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
OUTPUT_DIR = SCRIPT_DIR.parent / "assets"
OUTPUT_FILE = OUTPUT_DIR / "model.tflite"
SAVED_MODEL_DIR = OUTPUT_DIR / "saved_model"
MAX_SEQ_LEN = 128


def check_dependencies():
    """Check that required packages are importable."""
    required = {
        "transformers": "transformers",
        "tensorflow": "tensorflow",
        "numpy": "numpy",
    }
    missing = []
    for import_name, pip_name in required.items():
        try:
            __import__(import_name)
        except ImportError as e:
            print(f"   Import failed for '{import_name}': {e}")
            missing.append(pip_name)
    if missing:
        print(f"\nERROR: Missing packages: {', '.join(missing)}")
        print(f"Run:   pip install -r scripts\\requirements.txt")
        sys.exit(1)
    print("   All dependencies OK.")


def convert_model():
    """Convert HuggingFace model -> TF Keras -> TFLite."""

    os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

    print("Checking dependencies...")
    check_dependencies()

    import numpy as np
    import tensorflow as tf

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # ──────────────────────────────────────────────
    # Step 1: Load model directly in TensorFlow
    # ──────────────────────────────────────────────
    print(f"\nStep 1/3: Loading model in TensorFlow...")
    print(f"   Model: {MODEL_ID}")
    print(f"   This auto-converts PyTorch weights to TF format.")

    # Try multiple loading strategies in order of preference:
    # 1. TFAutoModel with safetensors (avoids torch.load CVE-2025-32434)
    # 2. TFAutoModel with from_pt=True (needs torch>=2.6)
    # 3. TFBertModel with safetensors
    # 4. TFBertModel with from_pt=True
    tf_model = None
    load_errors = []

    load_attempts = [
        ("TFAutoModel + safetensors", "TFAutoModel", {"from_pt": True, "use_safetensors": True}),
        ("TFAutoModel + torch", "TFAutoModel", {"from_pt": True}),
        ("TFBertModel + safetensors", "TFBertModel", {"from_pt": True, "use_safetensors": True}),
        ("TFBertModel + torch", "TFBertModel", {"from_pt": True}),
    ]

    for label, class_name, kwargs in load_attempts:
        if tf_model is not None:
            break
        try:
            from transformers import TFAutoModel, TFBertModel
            model_class = TFAutoModel if class_name == "TFAutoModel" else TFBertModel
            print(f"   Trying {label}...")
            tf_model = model_class.from_pretrained(MODEL_ID, **kwargs)
            print(f"   Model loaded via {label}.")
        except Exception as e:
            err_short = str(e).split('\n')[0][:120]
            load_errors.append(f"{label}: {type(e).__name__}: {err_short}")
            print(f"   {label} failed: {err_short}")

    if tf_model is None:
        print("\nERROR: Could not load model in TensorFlow.")
        for err in load_errors:
            print(f"   - {err}")
        print("\nFixes to try:")
        print("   pip install --upgrade torch>=2.6.0")
        print("   pip install safetensors")
        print("   pip install -r scripts\\requirements.txt")
        sys.exit(1)

    # ──────────────────────────────────────────────
    # Step 2: Create a concrete function and convert to TFLite
    # ──────────────────────────────────────────────
    print(f"\nStep 2/3: Converting to TFLite...")
    print(f"   Max sequence length: {MAX_SEQ_LEN}")

    # Define a serving function with fixed input shapes
    # TFLite requires static shapes (no dynamic batch/seq dims)
    @tf.function(input_signature=[
        tf.TensorSpec(shape=[1, MAX_SEQ_LEN], dtype=tf.int32, name="input_ids"),
        tf.TensorSpec(shape=[1, MAX_SEQ_LEN], dtype=tf.int32, name="attention_mask"),
        tf.TensorSpec(shape=[1, MAX_SEQ_LEN], dtype=tf.int32, name="token_type_ids"),
    ])
    def serve(input_ids, attention_mask, token_type_ids):
        outputs = tf_model(
            input_ids=input_ids,
            attention_mask=attention_mask,
            token_type_ids=token_type_ids,
            training=False,
        )
        return outputs.last_hidden_state

    # Trace the function to get a concrete function
    print("   Tracing model graph...")
    concrete_func = serve.get_concrete_function()

    # Convert to TFLite
    print("   Running TFLite converter...")
    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    # Use float16 quantization for smaller model size
    converter.target_spec.supported_types = [tf.float16]

    tflite_model = converter.convert()

    # Save the TFLite model
    OUTPUT_FILE.write_bytes(tflite_model)
    file_size_mb = OUTPUT_FILE.stat().st_size / 1024 / 1024
    print(f"   TFLite model saved: {OUTPUT_FILE}")
    print(f"   Size: {file_size_mb:.1f} MB")

    # ──────────────────────────────────────────────
    # Step 3: Verify the model works
    # ──────────────────────────────────────────────
    print(f"\nStep 3/3: Verifying TFLite model...")

    interpreter = tf.lite.Interpreter(model_path=str(OUTPUT_FILE))
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    print(f"   Inputs:  {[(d['name'], d['shape'].tolist()) for d in input_details]}")
    print(f"   Outputs: {[(d['name'], d['shape'].tolist()) for d in output_details]}")

    # Run a test inference with dummy data
    for detail in input_details:
        test_data = np.ones(detail["shape"], dtype=detail["dtype"])
        interpreter.set_tensor(detail["index"], test_data)

    interpreter.invoke()

    out = interpreter.get_tensor(output_details[0]["index"])
    print(f"   Test inference output shape: {out.shape}")
    print(f"   Output sample (first 5 values): {out[0][0][:5]}")

    print("\nDone! Model is ready for on-device inference.")
    print(f"   Output: {OUTPUT_FILE}")


if __name__ == "__main__":
    convert_model()
