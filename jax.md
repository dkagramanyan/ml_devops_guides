# Jax

Проверка использования cuda 

~~~
from jax.lib import xla_bridge
print(xla_bridge.get_backend().platform)
jax.devices()
~~~

# Navix

Если при импорте модуля navix вы получаете ошибку
~~~
ValueError: mutable default <class 'jaxlib.xla_extension.ArrayImpl'> for field position is not allowed: use default_factory
~~~

то проблема не в библиотеке, а в версии 3.11 python ( [пруф1](https://github.com/huggingface/datasets/issues/5230), [пруф2](https://github.com/ray-project/ray/issues/33232)). Достаточно создать новое окружение с python 3.10 и все нормально заведется
