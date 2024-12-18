Установка CUDA
--------------

### Локальная установка в окружение
**для windows и linux**

Предпочтительный метод установки CUDA для работы на python. Установка  в окружение
позволяет использовать одновременно несколько версий CUDA. Подробно установка описана [тут](https://towardsdatascience.com/setting-up-tensorflow-gpu-with-cuda-and-anaconda-onwindows-2ee9c39b5c44)

~~~
activate env
conda install -c anaconda cudatoolkit=10.1
~~~

## Установка на Ubuntu

У Nvidia есть для каждой версии cuda набор скриптов для установки. [Ссылка](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=24.04&target_type=deb_local)


### Глобальная установка в PATH
**для windows**

Более трудоемкий способ установки. Позволяет использовать только одну 
установленную версию CUDA.
Если вы не работаете с пакетом Anaconda или область видимости CUDA должна 
быть глобальной, выполните следующие действия
1) установите Microsoft Visual Studio 2017,2019
2) установите Cuda Toolkit нужной версии
3) скачайте CuDNN и переместите его в директорию C:\tools
4) добавьте в переменную среду пользователя PATH следующие пути

~~~
C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.0\bin
C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.0\extras\CUPTI\lib64
C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.0\include
C:\tools\cuda\bin
~~~

Подробно установка Cuda для TensorFlow
описана [тут](https://www.tensorflow.org/install/gpu?hl=ur)
