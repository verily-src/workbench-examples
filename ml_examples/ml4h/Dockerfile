FROM gcr.io/deeplearning-platform-release/tf-gpu.2-11.py310

RUN apt-get update && apt-get install less ffmpeg libsm6 libxext6 python3-tk libgl1-mesa-glx libxt-dev -y

RUN pip install -U matplotlib
RUN conda install ipyevents -y
RUN conda install ipycanvas -y
RUN pip install ipyannotations
RUN pip install  numcodecs vtk
RUN pip install tensorflow-io==0.29.0 tensorflow-addons==0.19.0 tensorflow_hub==0.13.0 tensorflow_probability==0.19.0 keras-tuner==1.3.5

RUN git clone https://github.com/broadinstitute/ml4h.git
WORKDIR ml4h
ADD tensorflow-requirements.txt ./docker/vm_boot_images/config/tensorflow-requirements.txt
RUN pip install -e .

WORKDIR ..

RUN pip install altair pydicom nibabel biosppy vega
RUN pip install jupyterlab-pygments==0.2.2 jupyterlab-git==0.41.0  jupyter-server-proxy
RUN pip install ipympl

RUN pip install tensorflow-text==2.11.0
RUN pip install opencv-python==4.8.1.78 opencv-python-headless==4.8.1.78
RUN pip install --upgrade protobuf==3.20

RUN conda install -c anaconda graphviz -y
RUN conda install nb_conda_kernels
RUN pip install nodejs plotly==5.15.0 jupytext==1.14.6
RUN pip install nbdime==3.2.0

RUN pip install -U ipywidgets
RUN pip install -U pyviz_comms==2.3.2
