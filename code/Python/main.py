import pandas as pd
import argparse
import os
import xgboost as xgb
import matplotlib.pyplot as plt
import numpy as np
from joblib import dump
from joblib import load
from xgboost import XGBRegressor
from xgboost import plot_importance
from sklearn import model_selection
from sklearn.model_selection import cross_validate
from sklearn.model_selection import train_test_split



def mean_absolute_percentage_error(y_true, y_pred):
    return np.mean(np.abs((y_true - y_pred) / y_true)) * 100
  
  

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # Sagemaker specific arguments. Defaults are set in the environment variables.
    parser.add_argument('--input_data_dir', type=str, default='output/data/')
    parser.add_argument('--output_data_dir', type=str, default='output/data/')
    parser.add_argument('--model_dir', type=str, default='model/')
    parser.add_argument('--input_file_name', type=str, default='sales_uplift_week2.csv')
    parser.add_argument('--model_name', type=str, default='xgboost_uplift2')
    
    args = parser.parse_args()
    
    input_data = pd.read_csv(os.path.join(args.input_data_dir, args.input_file_name))
    
    y = input_data['uplift2']
    X = input_data.drop(['date', 'is_markdown', 'uplift2'], axis=1)
    
    data_dmatrix = xgb.DMatrix(data=X,label=y)
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=123)
    xg_reg = xgb.XGBRegressor(objective ='reg:linear', colsample_bytree = 0.3, learning_rate = 0.1,
                max_depth = 5, alpha = 10, n_estimators = 10)
    xg_reg.fit(X_train,y_train)

    preds = xg_reg.predict(X_test)
    mape = mean_absolute_percentage_error(y_test, preds)
    print("MAPE: %f" % (mape))
    
    params = {"objective":"reg:linear",'colsample_bytree': 0.3,'learning_rate': 0.1,
                'max_depth': 5, 'alpha': 10}

    cv_results = xgb.cv(dtrain=data_dmatrix, params=params, nfold=3,
                    num_boost_round=50,early_stopping_rounds=10,metrics="rmse", as_pandas=True, seed=123)
                    
    xgb.plot_importance(xg_reg)
    plt.rcParams['figure.figsize'] = [5, 5]
    plt.show()
    
    feat_importance = xg_reg.get_booster().get_score(importance_type='gain')
    feat_importance_df = pd.DataFrame(feat_importance, index=[0])
    feat_importance_df.to_csv(os.path.join(args.output_data_dir, 'feature_importance_' + args.model_name + '.csv'))
    
    # save model to file
    dump(xg_reg, os.path.join(args.model_dir, args.model_name + '.dat'))
    
    ## Ordinal Encoding seems better
    
    
