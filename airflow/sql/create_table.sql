/*
Only used when we want to load data directly into the redshift data warehouse.
We then create a TABLE.
Not necessary if we plan to use redshift spectrum (external table).
*/

-- This SQL script creates a table in Redshift to store Reddit data.
begin;
CREATE TABLE IF NOT EXISTS reddit_data (
    id VARCHAR (225),
    title VARCHAR (225),
    score INT,
    num_comments INT,
    author VARCHAR (225),
    ESS_Updated VARCHAR (225)
);
end;
