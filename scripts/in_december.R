# Filter only December transactions
data$Transaction_Month <- format(data$`Transaction Date`, "%m")

# Keep only December (month number 12)
december_data <- data %>%
  filter(Transaction_Month == "12")

# Check the date range
summary(december_data$`Transaction Date`)
# Aggregate only December daily sales
daily_sales <- december_data %>%
  group_by(`Transaction Date`) %>%
  summarise(Total_Sales = sum(`Total Spent`, na.rm = TRUE)) %>%
  arrange(`Transaction Date`)

# ----------------------------
# Split Train/Test (80/20)
# ----------------------------
train_size <- round(0.8 * nrow(daily_sales))
train <- head(daily_sales, train_size)
test <- tail(daily_sales, nrow(daily_sales) - train_size)

# ----------------------------
# Add Day and Year features
# ----------------------------
train$Day <- as.numeric(format(train$`Transaction Date`, "%j"))
train$Year <- as.numeric(format(train$`Transaction Date`, "%Y"))
test$Day <- as.numeric(format(test$`Transaction Date`, "%j"))
test$Year <- as.numeric(format(test$`Transaction Date`, "%Y"))

# ----------------------------
# Linear Regression Model
# ----------------------------
lm_model <- lm(Total_Sales ~ Day + Year, data = train)
pred_lm <- predict(lm_model, test)

# ----------------------------
# ARIMA Model
# ----------------------------
sales_ts <- ts(train$Total_Sales, frequency = 7) # Weekly pattern assumption
model_arima <- auto.arima(sales_ts)
forecast_arima <- forecast(model_arima, h = nrow(test))

# ----------------------------
# Combine Predictions
# ----------------------------
results <- data.frame(
  Date = test$`Transaction Date`,
  Actual = test$Total_Sales,
  Linear_Pred = pred_lm,
  ARIMA_Pred = as.numeric(forecast_arima$mean)
)

# ----------------------------
# Model Evaluation
# ----------------------------
rmse_lm <- rmse(results$Actual, results$Linear_Pred)
rmse_arima <- rmse(results$Actual, results$ARIMA_Pred)
cat("Linear Regression RMSE (December):", rmse_lm, "\n")
cat("ARIMA RMSE (December):", rmse_arima, "\n")

# ----------------------------
# Visualizations
# ----------------------------

# 1️⃣ Linear Regression: Actual vs Predicted
ggplot(results, aes(x=Date)) +
  geom_line(aes(y=Actual, color="Actual")) +
  geom_line(aes(y=Linear_Pred, color="Predicted (Linear)")) +
  labs(title="December: Linear Model Actual vs Predicted",
       x="Date", y="Sales") +
  scale_color_manual(values=c("Actual"="black", "Predicted (Linear)"="blue")) +
  theme_minimal()

# 2️⃣ ARIMA: Actual vs Predicted
ggplot(results, aes(x=Date)) +
  geom_line(aes(y=Actual, color="Actual")) +
  geom_line(aes(y=ARIMA_Pred, color="Predicted (ARIMA)")) +
  labs(title="December: ARIMA Model Actual vs Predicted",
       x="Date", y="Sales") +
  scale_color_manual(values=c("Actual"="black", "Predicted (ARIMA)"="red")) +
  theme_minimal()

# 3️⃣ Combined: Actual vs ARIMA vs Linear
ggplot(results, aes(x=Date)) +
  geom_line(aes(y=Actual, color="Actual")) +
  geom_line(aes(y=ARIMA_Pred, color="ARIMA")) +
  geom_line(aes(y=Linear_Pred, color="Linear Regression")) +
  labs(title="December: Actual vs ARIMA vs Linear Regression",
       x="Date", y="Sales") +
  scale_color_manual(values=c("Actual"="black", "ARIMA"="red", "Linear Regression"="blue")) +
  theme_minimal()

