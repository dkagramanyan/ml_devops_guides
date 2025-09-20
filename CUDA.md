Установка CUDA
--------------

### Локальная установка в окружение

Предпочтительный метод установки CUDA для работы на python. Установка  в окружение
позволяет использовать одновременно несколько версий CUDA. Подробно установка описана [тут](https://towardsdatascience.com/setting-up-tensorflow-gpu-with-cuda-and-anaconda-onwindows-2ee9c39b5c44)

~~~
activate env
conda install -c anaconda cudatoolkit=10.1
~~~

## Ubuntu

### Простая ecnfyjdrf

Автоматическая простая установка  [тут](https://askubuntu.com/questions/1258904/how-do-i-know-which-nvidia-driver-i-need)


### Установка 

У Nvidia есть для каждой версии cuda набор скриптов для установки. [Ссылка](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=24.04&target_type=deb_local)

или можно установить через
```
sudo apt install nvidia-driver-550
```
или
```
sudo apt install nvidia-cuda-toolkit
```

### Удаление
Описано [тут](https://stackoverflow.com/questions/56431461/how-to-remove-cuda-completely-from-ubuntu), и [тут](https://forums.developer.nvidia.com/t/nvidia-smi-has-failed-because-it-couldnt-communicate-with-the-nvidia-driver-make-sure-that-the-latest-nvidia-driver-is-installed-and-running/197141/5)
```
sudo apt-get remove --purge '^nvidia-.*' '^libnvidia-.*' '^cuda-.*' 'nsight*' '*cublas*'
sudo apt-get install linux-headers-$(uname -r)
sudo apt autoremove
```

## Windows 
### Глобальная установка в PATH

Трудоемкий способ установки. Позволяет использовать только одну 
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
