# Data


### Archives

Extract via python
~~~
import tarfile
tar = tarfile.open("test.tar", "r")
tar.extractall()
~~~

Extract via python
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
