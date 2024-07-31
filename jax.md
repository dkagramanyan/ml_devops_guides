# Jax

Проверка использования cuda 

~~~
from jax.lib import xla_bridge
print(xla_bridge.get_backend().platform)
jax.devices()
~~~

jax + tqdm

~~~
import jax
import jax.numpy as jnp
from jax import lax
import time

# Initialize the progress bar
total_iterations=10000
progress_bar = tqdm(total=total_iterations)

# Define a host callback function to update the progress bar
def update_progress_bar():
    progress_bar.update(1)

# Define the function to be scanned
def body_fn(carry, x):
    carry = carry + x
    y = carry * 2
    
    time.sleep(0.1)
    jax.debug.callback(update_progress_bar)

    return carry, y


# Run the scan
carry, ys = lax.scan(body_fn, 0, jnp.arange(total_iterations))

# Close the progress bar after computation
progress_bar.close()
~~~

# Navix

Если при импорте модуля navix вы получаете ошибку
~~~
ValueError: mutable default <class 'jaxlib.xla_extension.ArrayImpl'> for field position is not allowed: use default_factory
~~~

то проблема не в библиотеке, а в версии 3.11 python ( [пруф1](https://github.com/huggingface/datasets/issues/5230), [пруф2](https://github.com/ray-project/ray/issues/33232)). Достаточно создать новое окружение с python 3.10 и все нормально заведется
