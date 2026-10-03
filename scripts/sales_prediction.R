# -----------------------------------------------
# MINI PROJECT: PRODUCT SALES PREDICTION
# Using ARIMA and Linear Regression in R
# -----------------------------------------------

# Step 1: Load Required Libraries
library(readr)
library(dplyr)
library(ggplot2)
library(forecast)
library(Metrics)

# Step 2: Import Dataset
data <- read_csv("data/retail_store_sales.csv")

# Step 3: Initial Data Overview
cat("\n--- Initial Data Overview ---\n")
str(data)
summary(data)
head(data)

# Step 4: Check Missing Values
cat("\n--- Missing Values in Each Column ---\n")
colSums(is.na(data))
cat("Total Rows with Any Missing Values:", sum(!complete.cases(data)), "\n")

# Step 5: Data Cleaning
## Replace missing values
# For numeric columns
data$Quantity[is.na(data$Quantity)] <- median(data$Quantity, na.rm = TRUE)
data$`Total Spent`[is.na(data$`Total Spent`)] <- median(data$`Total Spent`, na.rm = TRUE)

# For categorical columns
data$`Payment Method`[is.na(data$`Payment Method`)] <- "Unknown"
data$Category[is.na(data$Category)] <- "Misc"

## Remove any completely empty rows
data <- data[complete.cases(data), ]

## Remove duplicates
data <- distinct(data)

# Step 6: Fix Data Types
data$`Transaction Date` <- as.Date(data$`Transaction Date`, format="%Y-%m-%d")
data$Quantity <- as.numeric(data$Quantity)
data$`Total Spent` <- as.numeric(data$`Total Spent`)

# Step 7: Detect and Handle Outliers in Total Spent
q1 <- quantile(data$`Total Spent`, 0.25)
q3 <- quantile(data$`Total Spent`, 0.75)
iqr <- q3 - q1

data <- data %>%
  filter(`Total Spent` > (q1 - 1.5 * iqr) & `Total Spent` < (q3 + 1.5 * iqr))

# Step 8: Recheck Cleaned Data
cat("\n--- After Cleaning ---\n")
summary(data)
colSums(is.na(data))

# Step 9: Aggregate Daily Total Sales
daily_sales <- data %>%
  group_by(`Transaction Date`) %>%
  summarise(Total_Sales = sum(`Total Spent`, na.rm = TRUE)) %>%
  arrange(`Transaction Date`)

# Plot daily sales
ggplot(daily_sales, aes(x=`Transaction Date`, y=Total_Sales)) +
  geom_line(color="darkgreen", lwd=1.1) +
  labs(title="Daily Total Sales Over Time", x="Date", y="Sales")

# Step 10: Split Train/Test (80/20)
train_size <- round(0.8 * nrow(daily_sales))
train <- head(daily_sales, train_size)
test <- tail(daily_sales, nrow(daily_sales) - train_size)

# Step 11: Linear Regression Model
train$Day <- as.numeric(format(train$`Transaction Date`, "%j"))
train$Year <- as.numeric(format(train$`Transaction Date`, "%Y"))
test$Day <- as.numeric(format(test$`Transaction Date`, "%j"))
test$Year <- as.numeric(format(test$`Transaction Date`, "%Y"))

lm_model <- lm(Total_Sales ~ Day + Year, data = train)
summary(lm_model)

pred_lm <- predict(lm_model, test)

# Step 12: ARIMA Model
sales_ts <- ts(train$Total_Sales, frequency = 7) # Weekly pattern assumption
model_arima <- auto.arima(sales_ts)
summary(model_arima)

forecast_arima <- forecast(model_arima, h = nrow(test))

# Step 13: Combine Predictions
results <- data.frame(
  Date = test$`Transaction Date`,
  Actual = test$Total_Sales,
  Linear_Pred = pred_lm,
  ARIMA_Pred = as.numeric(forecast_arima$mean)
)

# Step 14: Model Evaluation
cat("\n--- Model Evaluation ---\n")
rmse_lm <- rmse(results$Actual, results$Linear_Pred)
rmse_arima <- rmse(results$Actual, results$ARIMA_Pred)
cat("Linear Regression RMSE:", rmse_lm, "\n")
cat("ARIMA RMSE:", rmse_arima, "\n")

# Step 15: Visualizations

## 1️⃣ Linear Regression: Actual vs Predicted
ggplot(results, aes(x=Date)) +
  geom_line(aes(y=Actual, color="Actual")) +
  geom_line(aes(y=Linear_Pred, color="Predicted (Linear)")) +
  labs(title="Linear Model: Actual vs Predicted",
       x="Date", y="Sales") +
  scale_color_manual(values=c("Actual"="black", "Predicted (Linear)"="blue")) +
  theme_minimal()

## 2️⃣ ARIMA: Actual vs Predicted
ggplot(results, aes(x=Date)) +
  geom_line(aes(y=Actual, color="Actual")) +
  geom_line(aes(y=ARIMA_Pred, color="Predicted (ARIMA)")) +
  labs(title="ARIMA Model: Actual vs Predicted",
       x="Date", y="Sales") +
  scale_color_manual(values=c("Actual"="black", "Predicted (ARIMA)"="red")) +
  theme_minimal()

## 3️⃣ Combined: Actual vs ARIMA vs Linear
ggplot(results, aes(x=Date)) +
  geom_line(aes(y=Actual, color="Actual")) +
  geom_line(aes(y=ARIMA_Pred, color="ARIMA")) +
  geom_line(aes(y=Linear_Pred, color="Linear Regression")) +
  labs(title="Actual vs ARIMA vs Linear Regression",
       x="Date", y="Sales") +
  scale_color_manual(values=c("Actual"="black", "ARIMA"="red", "Linear Regression"="blue")) +
  theme_minimal()

