-- Create keyspace
CREATE KEYSPACE IF NOT EXISTS cluster_benchmark WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : '1' };

-- Create table
CREATE TABLE IF NOT EXISTS cluster_benchmark.words ( uuid text, word text, b64 text, PRIMARY KEY ( uuid ));

-- Bulk import from csv
COPY cluster_benchmark.words ( uuid, word, b64) FROM 'words.csv';
