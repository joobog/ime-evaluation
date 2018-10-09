# I/O-Performance exploration

## Running performance tests
```sbatch batch_job.sh``` 

## Put all results in a SQLite3 data base
```mkdb.py <db_file_name.db>``` 

## Evaluation with R
1. ```eval_analysis.R <db_file_name.db> <output_folder>```	
1. ```eval_netcdfbench.R <db_file_name.db> <output_folder>```
1. ```eval_openclose.R <db_file_name.db> <output_folder>``` 	
1. ```eval_performance.R <db_file_name.db> <output_folder>``` 	
1. ```eval_readwrite.R <db_file_name.db> <output_folder>```
	
