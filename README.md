# Product Markdown Forecast

## Context:
It is October 2018 and a fashion retailer, “The Company” (C), is entering a major markdown season
and would like to plan ahead.

## Objective:

In order to maximize profit, C would like to have a model to predict the impact on sales of a particular
markdown on a particular product. The objective of this exercise is to help C make its markdown plans.

## Data:

The historical data we will consider was recorded in October 2017 in Nordic countries. The weather
was particularly cold during that period, as customers were reviewing marked down offers for the fall
collections.

The data set is composed of three weeks; the first week was the one just before the markdown season
began, with no major discounts applied. For the sake of clarity, we will call the week without
markdowns for **week 0**, the first week with markdowns for **week 1**, and the second week of
markdowns for **week 2**.

The two datasets (more detailed explanations in the Appendix below):
- Sales_master.csv, which contains the sales data
- Product_table.csv, which contains generic information for each variant of each article. NB: An
“article” is a product with a particular color/print. A “variant” is a version of an article with a
particular size. For instance:
  - Product **512787** is a V-neck sweater
  - Article **512787004** is a red V-neck sweater
  - Variants **512787004003**, **512787004004** and **512787004006** are three different sizes of the red V-neck sweater. Notice how the 9 first numbers of the variant ID is the article ID.

# Task

Now, it is the end of September 2018, and the markdown period for October 2018 starts next week. Using the data you have, build a model to predict demand. Using your model, suggest a plan of action for markdowns for the first week of markdown October 2018.

## Questions:

1) What type of trends can you observe per week and per product? What can you tell about the
discounts and their impact on sales?
Tip: a reference variable for this study is the uplift, i.e. the factor between the sales during a
markdown week and the sales during a week without markdown close in time.
2) Is it possible to predict the uplift for the first week of markdowns with the information you
have? What would be the key variables? (please **do not take week** 2 into account in this
question)
3) ~~Suggest a specific plan of action for markdowns in October 2018, based on your observations
and models on week 1~~. If you had data on stock (number of items in inventory), how would
you leverage them? (please **do not take week 2** into account in this question)
4) (Extra point question) Please answer questions 2) and 3) considering both week 1 and week 2
data. Does it changes your plan of action? How?

## Appendix
- Sales_master.csv:
  - Gross_amount: the total sales that were generated with this particular variant **not taking discount into account**
  - Net_amount: the total sales that were generated with this particular **after discount** (so it shows what the customers actually paid)
  - Purchases: number of item sold
- Product_table.csv:
  -Index_group_name, department name and product_type_name represent three levels of granularity describing the product (index being the higher-lever one and product_type_name the lowest)
  
  
# Reproducibility
  
This project has been developed in a windows machine using R and Python for different parts of the task. When trying to open the R project it is possible that you get the following warning:
  
  
``` r
* Creating virtual environment 'renv-python-3.8.7' ... Error: invalid version specification ‘No se encontró Python; ejecuta sin argumentos para instalar desde Microsoft Store o deshabilita este acceso directo en Configuración > Administrar alias de ejecución de la aplicación.’
Además: Warning message:
In system2(python, args, stdout = TRUE, stderr = TRUE) :
  comando ejecutado '"C:/Users/Asus/AppData/Local/Microsoft/WindowsApps/python3.exe" -c "from platform import python_version; print(python_version())"' tiene estatus 9009
Traceback (most recent calls last):
19: source("renv/activate.R")
18: withVisible(eval(ei, envir))
17: eval(ei, envir)
16: eval(ei, envir)
15: local(...) at activate.R#2
14: eval.parent(substitute(eval(quote(expr), envir)))
13: eval(expr, p)
12: eval(expr, p)
11: eval(quote(...), new.env())
10: eval(quote(...), new.env())
 9: if (renv_bootstrap_load(project, libpath, version))
      return(TRUE) at activate.R#410
 8: renv::load(project) at activate.R#394
 7: renv_load_python(project, lockfile$Python)
 6: renv_load_python_env(fields, renv_use_python_virtualenv)
 5: loader(project = project, version = version, name = name)
 4: renv_python_virtualenv_create(python, path)
 3: numeric_version(version)
 2: .make_numeric_version(x, strict, .standard_regexps()$valid_numeric_version)
 1: stop(gettextf("invalid version specification %s", paste(sQuote(unique(x[!ok])), 
        collapse = ", ")), call. = FALSE, domain = NA)
```

This is because [renv](https://rstudio.github.io/renv/articles/python.html) is not able to find your python installation. Please ensure that Python was added to the PATH environment variable: https://geek-university.com/python/add-python-to-the-windows-path/.

After that, you will restore the python environment by running:

```r
renv::use_python(python="C:/Users/Asus/AppData/Local/Programs/Python/Python38/python.exe", type = "virtualenv")
```

Python dependencies contain [gluon-ts](https://github.com/awslabs/gluon-ts), which in windows requires the VS Code Build tools. If VS Code Build tools are not installed you might receive the following error when restoring the python environment:

```python
    Running setup.py install for ujson: finished with status 'error'
    ERROR: Command errored out with exit status 1:
     command: 'C:\Users\Asus\PRODUC~1\renv\python\VIRTUA~1\RENV-P~1.7\Scripts\python.exe' -u -c 'import sys, setuptools, tokenize; sys.argv[0] = '"'"'C:\\Users\\Asus\\AppData\\Local\\Temp\\pip-install-_4abze5n\\ujson\\setup.py'"'"'; __file__='"'"'C:\\Users\\Asus\\AppData\\Local\\Temp\\pip-install-_4abze5n\\ujson\\setup.py'"'"';f=getattr(tokenize, '"'"'open'"'"', open)(__file__);code=f.read().replace('"'"'\r\n'"'"', '"'"'\n'"'"');f.close();exec(compile(code, __file__, '"'"'exec'"'"'))' install --record 'C:\Users\Asus\AppData\Local\Temp\pip-record-w7s20iz_\install-record.txt' --single-version-externally-managed --compile --install-headers 'C:\Users\Asus\PRODUC~1\renv\python\VIRTUA~1\RENV-P~1.7\include\site\python3.8\ujson'
         cwd: C:\Users\Asus\AppData\Local\Temp\pip-install-_4abze5n\ujson\
    Complete output (6 lines):
    Warning: 'classifiers' should be a list, got type 'filter'
    running install
    running build
    running build_ext
    building 'ujson' extension
    error: Microsoft Visual C++ 14.0 is required. Get it with "Build Tools for Visual Studio": https://visualstudio.microsoft.com/downloads/
 ```
 
 You can find the download link [here](https://visualstudio.microsoft.com/es/visual-cpp-build-tools/). After everything is ready you only need to run:
 
 ```r
renv::restore()
```

Which in the background will install the dependencies from the requirements.txt file available in this repository
 
 ``` python
 Successfully installed Pillow-8.1.0 gluonts-0.6.5 graphviz-0.8.4 hijri-converter-2.1.1 holidays-0.10.5.2 idna-2.6 kiwisolver-1.3.1 korean-lunar-calendar-0.2.1 matplotlib-3.3.4 mxnet-1.7.0.post1 numpy-1.16.6 pandas-1.2.1 pyparsing-2.4.7 python-dateutil-2.8.1 requests-2.18.4 toolz-0.11.1 tqdm-4.56.0 ujson-1.35 urllib3-1.22
WARNING: You are using pip version 20.2.3; however, version 21.0.1 is available.
You should consider upgrading via the 'C:\Users\Asus\PRODUC~1\renv\python\VIRTUA~1\RENV-P~1.7\Scripts\python.exe -m pip install --upgrade pip' command.
* Restored Python packages from 'C:/Users/Asus/product-markdown-forecast/requirements.txt'.
 ```
