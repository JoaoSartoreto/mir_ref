<img src="docs/img/mir_ref_logo.svg" align="left" height="110">

# mir_ref

Representation Evaluation Framework for Music Information Retrieval tasks | [Paper](https://arxiv.org/abs/2312.05994)

`mir_ref` is an open-source library for evaluating audio representations (embeddings or others) on a variety of music-related downstream tasks and datasets.

**This fork contains a fully integrated, optimized implementation of MFCC (Mel-Frequency Cepstral Coefficients) feature extraction, designed for scientific comparison with deep learning models.**  
Branch maintained by [JoaoSartoreto](https://github.com/JoaoSartoreto), focused on Music Information Retrieval research and reproducibility for TCC/monography purposes.

---

## 🆕 What's new in this fork?

- **MFCC extraction is now natively supported as a feature**:  
  Just set `mfcc` as a feature in your config YAML.
- **Flexible configuration**:  
  All MFCC parameters (`n_mfcc`, `n_mels`, `fmin`, `fmax`, `dct_type`, `norm`, `window_size_ms`, `max_frames`) are loaded from the YAML config.
- **Extraction fully integrated into the mir_ref pipeline**:  
  MFCC embeddings are flattened to 1D vectors and saved as `.npy`, compatible with the rest of the pipeline (train/evaluate).
- **Efficient frame handling**:  
  Automatic frame trimming or zero-padding ensures every MFCC feature has a consistent shape for model input.
- **No pre-saved full MFCC matrices**:  
  The final implementation only saves the processed, fixed-size, flattened MFCC vector for each audio, not the full time-frequency matrix.

---

## Installation

Clone this repository, create and activate a Python >=3.9 environment, and install requirements:

```sh
git clone https://github.com/JoaoSartoreto/mir_ref.git
cd mir_ref
pip install -r requirements.txt
```

---

## MFCC Example Usage

1. **Configure your experiment** in YAML, setting `mfcc` as the feature, and parameters as desired:

```yaml
experiments:
  - task:
      name: autotagging
      type: multilabel_classification
      feature_aggregation: mean
    datasets:
      - name: magnatagatune
        type: custom
        dir: data/magnatagatune/
    features:
      - mfcc
    feature_parameters:
      mfcc:
        n_mfcc: 13
        n_mels: 40
        fmin: 20
        fmax: 8000
        dct_type: 2
        norm: ortho
        window_size_ms: 20
        max_frames: 250
    probes:
      - type: classifier
        emb_shape: infer
        hidden_units: []
        output_activation: sigmoid
        optimizer: adam
        learning_rate: 1.0e-3
        batch_size: 1083
        epochs: 100
        patience: 10
```

2. **Extract MFCC features**:

```sh
python run.py extract -c your_config.yml
```

3. **Train and evaluate** (after extracting features):

```sh
python run.py train -c your_config.yml
python run.py evaluate -c your_config.yml
```

---

## MFCC Extraction Details

- **Librosa** is used for MFCC extraction, and all parameters can be customized via YAML.
- Each audio file is normalized, MFCCs are extracted and scaled to [0,1], time frames are either sub-sampled or padded, and the final MFCC matrix is flattened before saving.
- Output shape for each MFCC vector is `(max_frames * n_mfcc,)` (1D numpy array).

---

## Advanced

You can combine MFCCs with other features, test different configurations, and use all the functionalities of `mir_ref` as described in the [original README](https://github.com/filiperochalopes/mir_ref).

---

## Disclaimer

This fork is experimental and focuses on **research and reproducibility** for TCC/academic purposes.  
If you use or adapt this implementation, please **cite the original paper** and, if relevant, this fork.  
Feel free to open issues or pull requests!

---

## Citing

If you use `mir_ref`, please cite the following [paper](https://arxiv.org/abs/2312.05994):

```bibtex
@inproceedings{mir_ref,
    author = {Christos Plachouras and Pablo Alonso-Jim\'enez and Dmitry Bogdanov},
    title = {mir_ref: A Representation Evaluation Framework for Music Information Retrieval Tasks},
    booktitle = {37th Conference on Neural Information Processing Systems (NeurIPS), Machine Learning for Audio Workshop},
    address = {New Orleans, LA, USA},
    year = 2023,
}
```

