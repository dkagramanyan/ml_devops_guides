TensorFlow
----------

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

## Apple silicon

Установка хорошо описана [тут](https://jamescalam.medium.com/hugging-face-and-sentence-transformers-on-m1-macs-4b12e40c21ce) 
