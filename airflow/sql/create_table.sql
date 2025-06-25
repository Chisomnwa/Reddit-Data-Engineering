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
