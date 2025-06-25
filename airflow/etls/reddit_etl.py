import praw
from praw import Reddit
import sys

import pandas as pd
import numpy as np

import os
import sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.constants import POST_FIELDS

def connect_reddit(client_id, client_secret, user_agent) -> Reddit:
    """
    Connect to Reddit using PRAW (Python Reddit API Wrapper).

    Args:
        client_id (str): Reddit application client ID.
        client_secret (str): Reddit application client secret.
        user_agent (str): User agent string for the Reddit API.

    Returns:
        Reddit: An instance of the Reddit class connected to the API.
    """
    try:
        reddit = praw.Reddit(
            client_id=client_id,
            client_secret=client_secret,
            user_agent=user_agent
        )
        return reddit
    except Exception as e:
        print(e)
        sys.exit(1)

def extract_posts(reddit_instance: Reddit, subreddit: str, time_filter: str, limit: None):
    """
    Extract posts from a specified subreddit.

    Args:
        reddit (Reddit): An instance of the Reddit class.
        subreddit (str): The name of the subreddit to extract posts from.
        time_filter (str): Time filter for the posts (e.g., 'day', 'week', 'month').
        limit (int, optional): Maximum number of posts to extract. Defaults to None.

    Returns:
        list: A list of extracted posts.
    """
    subreddit = reddit_instance.subreddit(subreddit)
    posts = subreddit.top(time_filter=time_filter, limit=limit)

    post_lists = []

    for post in posts:
        post_dict = vars(post)
        # post = {key: post_dict[key] for key in POST_FIELDS} 
        '''
        The above line was causing an error because the 'author' field in the post_dict
        was a Redditor object, which is not serializable to a DataFrame.
        '''
        post = {key: str(post_dict.get(key, "")) for key in POST_FIELDS}
        post_lists.append(post)

    return post_lists

def transform_data(post_df: pd.DataFrame) -> pd.DataFrame:
    """
    Transform the extracted post data.

    Args:
        post_df (pd.DataFrame): DataFrame containing the extracted posts.

    Returns:
        pd.DataFrame: Transformed DataFrame.
    """
    # Example transformation: Convert 'created_utc' to datetime
    post_df['created_utc'] = pd.to_datetime(post_df['created_utc'], unit='s')
    post_df['over_18'] = np.where((post_df['over_18'] == 'True'), True, False)
    post_df['author'] = post_df['author'].astype(str)
    edited_mode = post_df['edited'].mode()
    post_df['edited'] = np.where(post_df['edited'].isin([True, False]),
                                 post_df['edited'], edited_mode).astype(bool)
    post_df['num_comments'] = post_df['num_comments'].astype(int)
    post_df['score'] = post_df['score'].astype(int)
    post_df['title'] = post_df['title'].astype(str)
    
    # Add more transformations as needed
    return post_df

def load_data_to_csv(data: pd.DataFrame, path: str):
    """
    Load the DataFrame to a CSV file.

    Args:
        data (pd.DataFrame): DataFrame to be saved.
        path (str): Path where the CSV file will be saved.
    """
    data.to_csv(path, index=False)
    print(f"Data successfully saved to {path}") 