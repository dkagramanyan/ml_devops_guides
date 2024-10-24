ML
--

## Инференс моделей

Инференс [Yolo](https://github.com/ArmageddonReloadedDK/video_stream) на CPU и GPU

Инференс [Yolo](https://github.com/noDGodyaev/dmx_w_body_detection) в программе управления DMX фонарями по протоколу ArtNet

Fine-Tune [rubert-tiny](https://huggingface.co/cointegrated/rubert-tiny) для задачи классификации комментариев *Will be there soon*

## Tensorflow

[Таблица](https://www.tensorflow.org/install/source#gpu) совместимости версий tensroflow 
и CUDA

Полный процесс установки в [гайде](https://www.tensorflow.org/install/pip#virtual-environment-install) от разработчиков

Тестовый код для проверки работы TensorFlow-gpu и CUDA
~~~
import tensorflow as tf  # 2.x
tf.compat.v1.disable_eager_execution() # need to disable eager in TF2.x
# Build a graph.
a = tf.constant(5.0)
b = tf.constant(6.0)
c = a * b

# Launch the graph in a session.
sess = tf.compat.v1.Session()

# Evaluate the tensor `c`.
print(sess.run(c)) # prints 30.0
~~~

Проверка видимости видеокарты
~~~
from tensorflow.python.client import device_lib

print(device_lib.list_local_devices())
print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))
~~~

Создание ограничения для Tensorflow на заполнение всей видеопамяти видеокарты
~~~
gpus = tf.config.list_physical_devices('GPU')
tf.config.experimental.set_memory_growth(gpus[0], True)
~~~

## Tensorflow Apple silicon

Установка хорошо описана [тут](https://jamescalam.medium.com/hugging-face-and-sentence-transformers-on-m1-macs-4b12e40c21ce) 


## Pytorch

Проверка видимости видеокарты
~~~
import torch

print(torch.cuda.is_available())     # Returns a bool indicating if CUDA is currently available.
print(torch.cuda.current_device())   # Returns the index of a currently selected device.
print(torch.cuda.device(0))          # Context-manager that changes the selected device.
print(torch.cuda.device_count())     # Returns the number of GPUs available.
print(torch.cuda.get_device_name(0)) # Gets the name of a device.
~~~

Отключение cuda девайсов
~~~
torch.cuda.is_available = lambda : False
~~~


## Полезные ссылки
[Гайд от Rubbix](https://rubrix.readthedocs.io/en/master/tutorials/01-labeling-finetuning.html) по дообучению модели Bert
 в качестве текстового классификатора на их датасете с помощью высокоуровнего API от [Transformers](https://huggingface.co/transformers/index.html)
