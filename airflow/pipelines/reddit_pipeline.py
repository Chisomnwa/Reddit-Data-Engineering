import pandas as pd
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from utils.constants import CLIENT_ID, CLIENT_SECRET, USER_AGENT, OUTPUT_PATH
from etls.reddit_etl import connect_reddit, extract_posts, transform_data, load_data_to_csv


def reddit_pipeline(file_name: str, subreddit: str, time_filter='day', limit=None):
    # connecting to reddit instance
    instance = connect_reddit(CLIENT_ID, CLIENT_SECRET, USER_AGENT)
    # extraction
    posts = extract_posts(instance, subreddit, time_filter, limit)
    post_df = pd.DataFrame(posts)
    # transformation
    post_df = transform_data(post_df)
    # loading to csv
    file_path = f'{OUTPUT_PATH}/{file_name}.csv'
    load_data_to_csv(post_df, file_path)


    # Print column names to terminal/log
    # print("Extracted Data Columns:", post_df.columns.tolist())

    return file_path
    # return post_df

# ✅ Add this for local testing
# This worrks if we returned post_df instead of file_path
if __name__ == "__main__":
    df = reddit_pipeline(
        file_name="test_file",
        subreddit="dataengineering",
        time_filter="day",
        limit=10
    )
    print("Extracted Data Columns:", df.columns.tolist())
    print(df.head())  # optional: see a preview of the data