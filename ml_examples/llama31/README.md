
# Run inference on Verily Workbench using the Llama 3.1 8B model

The [vwb_8b_v100_llama31_hf.ipynb](./vwb_8b_v100_llama31_hf.ipynb) notebook example shows how to
load and run inference with a [Llama 3.1
model](https://llama.meta.com/docs/model-cards-and-prompt-formats/llama3_1/) on Verily Workbench,
using the [Huggingface](https://huggingface.co/) libraries and model access.

You'll need a Huggingface [account](https://huggingface.co/join) and [access
token](https://huggingface.co/settings/tokens). You'll also need to apply for *approval to access
the Llama 3.1 model files*.  You'll find a link to do that when you access one of the Llama models
from Huggingface, e.g.: https://huggingface.co/meta-llama/Meta-Llama-3.1-70B-Instruct

This notebook uses the Huggingface `transformers` library for model inference, and uses the LLama
3.1 8B-Instruct model: https://huggingface.co/meta-llama/Meta-Llama-3.1-70B-Instruct

Create a **Verily Workbench JupyterLab notebook environment** to run this example. **Use 8 CPUs, and
1 v100 GPU**.  With that configuration, the notebook costs ~3.01/hr to run.

Pick the **TensorFlow image** when you create the notebook environment.
