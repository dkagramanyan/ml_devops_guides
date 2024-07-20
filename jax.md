# Jax

Проверка использования cuda 

~~~
from jax.lib import xla_bridge
print(xla_bridge.get_backend().platform)
jax.devices()
~~~
