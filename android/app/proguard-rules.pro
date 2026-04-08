# TFLite Flutter plugin — suppress R8 warnings for optional GPU delegate classes
# These classes are only needed if using GPU acceleration (we use CPU/XNNPACK)
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-dontwarn org.tensorflow.lite.gpu.GpuDelegate
