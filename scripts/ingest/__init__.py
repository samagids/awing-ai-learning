"""Awing training corpus ingestion tools.

This package builds and maintains the `corpus/` tree — the canonical,
provenance-tracked inventory of every piece of raw Awing training data
on disk.

Entry points:
  build_manifest  — walk corpus/raw/ (and registered legacy paths) and
                    emit corpus/manifest.jsonl, one record per data file.
  bible           — (requires Bible Brain API key) fetch Bible text +
                    audio + timestamps into corpus/raw/bible/.
  youtube         — wrap yt-dlp to drop new videos into corpus/raw/youtube/.
  pdf             — extract text from PDF books into corpus/raw/books/.

Philosophy:
  Raw data is never modified in place. The manifest points at it.
  Derivative pipelines (alignment, training-set construction, model
  training) read from the manifest and write into corpus/aligned/ or
  models/, never into corpus/raw/.
"""
