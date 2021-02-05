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
markdowns for week 0, the first week with markdowns for week 1, and the second week of
markdowns for week 2.

The two datasets (more detailed explanations in the Appendix below):
- Sales_master.csv, which contains the sales data
- Product_table.csv, which contains generic information for each variant of each article. NB: An
“article” is a product with a particular color/print. A “variant” is a version of an article with a
particular size. For instance:
  - Product 512787 is a V-neck sweater
  - Article 512787004 is a red V-neck sweater
  - Variants 512787004003, 512787004004 and 512787004006 are three different sizes of the red V-neck sweater. Notice how the 9 first numbers of the variant ID is the article ID.

# Task

Now, it is the end of September 2018, and the markdown period for October 2018 starts next week. Using the data you have, build a model to predict demand. Using your model, suggest a plan of action for markdowns for the first week of markdown October 2018.

## Questions:

1) What type of trends can you observe per week and per product? What can you tell about the
discounts and their impact on sales?
Tip: a reference variable for this study is the uplift, i.e. the factor between the sales during a
markdown week and the sales during a week without markdown close in time.
2) Is it possible to predict the uplift for the first week of markdowns with the information you
have? What would be the key variables? (please do not take week 2 into account in this
question)
3) Suggest a specific plan of action for markdowns in October 2018, based on your observations
and models on week 1. If you had data on stock (number of items in inventory), how would
you leverage them? (please do not take week 2 into account in this question)
4) (Extra point question) Please answer questions 2) and 3) considering both week 1 and week 2
data. Does it changes your plan of action? How?

## Appendix
- Sales_master.csv:
o Gross_amount: the total sales that were generated with this particular variant not
taking discount into account
o Net_amount: the total sales that were generated with this particular after discount
(so it shows what the customers actually paid)
o Purchases: number of item sold
- Product_table.csv:
General Information
o Index_group_name, department name and product_type_name represent three levels
of granularity describing the product (index being the higher-lever one and
product_type_name the lowest)
