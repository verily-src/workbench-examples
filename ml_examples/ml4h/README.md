
# ML4H example notebooks

This directory holds some examples of using the [ml4h](https://github.com/broadinstitute/ml4h)
toolkit on a Verily Workbench notebook environment, along with a Dockerfile that can be used to
build a custom container for the notebook env.

ML4H is a toolkit from the Broad Institute for machine learning on clinical data of all kinds
including genetics, labs, imaging, clinical notes, and more. You can learn more from visiting the
repo, e.g. [here](https://github.com/broadinstitute/ml4h/blob/master/README.md) and
[here](https://github.com/broadinstitute/ml4h/blob/master/RECIPE_EXAMPLES.md).

This directory also includes slightly modified versions of some of the notebooks from the ml4h repo, here:
https://github.com/broadinstitute/ml4h/tree/master/notebooks.
`ML4H_Model_Factory_Intro.ipynb` is modified to swap in a different public GCS bucket for some public data.
`mnist_survival_analysis_demo.ipynb` is modified to fix an import error.
The notebooks have also been augmented with a bit of Workbench-related information, but are otherwise
unchanged from the originals.

## Running the examples

These notebooks run best in an environment with **at least 1 GPU** attached.

To run the examples, create a custom-container-based notebook environment using this image:
`gcr.io/terra-vdevel-cutting-date-7064/ml4h:v2`, which is built from the `Dockerfile` in this
directory. If you prefer, you can create your own image from the Dockerfile instead.
When you create the notebook environment, use 1 GPU (e.g., a V100).

Alternately, you can try running the `ml4h_setup.ipynb` notebook from a Tensorflow notebook
environment. (This installs `ml4h` via `pip` rather than directly from its repo, and has other
config differences).

**Troubleshooting tip**: If you see GPU-related or ML framework-related errors running a notebook
after having run another previously, **try shutting down all the other notebook kernels** and trying
again, to make sure no other process has grabbed the GPU.
