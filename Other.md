## Прочее

~~~
import tarfile
tar = tarfile.open("test.tar", "r")
tar.extractall()
~~~

## Conda-forge

~~~
conda install -c conda-forge ffmpeg-python
~~~

## Полезные ссылки
[Гайд от Rubbix](https://rubrix.readthedocs.io/en/master/tutorials/01-labeling-finetuning.html) по дообучению модели Bert
 в качестве текстового классификатора на их датасете с помощью высокоуровнего API от [Transformers](https://huggingface.co/transformers/index.html)


~~~
from py7zr import SevenZipFile

def extract_7z_file(input_file, output_directory):
    """
    Extracts a 7z file to the specified output directory.

    :param input_file: Path to the 7z file.
    :param output_directory: Path to the output directory where files will be extracted.
    """
    with SevenZipFile(input_file, mode='r') as s7z:
        s7z.extractall(path=output_directory)
    print(f"Extraction completed successfully to {output_directory}")

# Example usage
input_7z_file = '256-768.7z'
output_directory = '.'
extract_7z_file(input_7z_file, output_directory)
~~~

SFTPGo
------

~~~
docker run \
  -p 8080:443 \
  -p 2022:2022 \
  -v "/mnt/c/ssl_certificates:/ssl_certificates" \
  --mount type=bind,source=/mnt/g/ftp/data,target=/srv/sftpgo \
  --mount type=bind,source=/mnt/g/ftp/home,target=/var/lib/sftpgo \
  -e SFTPGO_HTTPD__BINDINGS__0__PORT=443 \
  -e SFTPGO_HTTPD__BINDINGS__0__ADDRESS=0.0.0.0 \
  -e SFTPGO_HTTPD__BINDINGS__0__ENABLE_HTTPS=1 \
  -e SFTPGO_HTTPD__BINDINGS__0__CERTIFICATE_FILE=/ssl_certificates/certificate.crt \
  -e SFTPGO_HTTPD__BINDINGS__0__CERTIFICATE_KEY_FILE=/ssl_certificates/certificate.key \
  -d drakkan/sftpgo:latest
~~~
