#property copyright "Created By Ali Sawari"
#property version   "1.00"
#property description "BollingerBands SuperStrat RANGE Indicator"

#include <stdlib.mqh>
#include <stderror.mqh>

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 5
#property indicator_color1 0xFFAA00
#property indicator_label1 "BB-R Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 5
#property indicator_color2 0x0000FF
#property indicator_label2 "BB-R Sell"

const string ALERT_MSG_BUY = "Buy BB-";
const string ALERT_MSG_SELL = "Sell BB-";

const int BB_SHORT = 8;
const int BB_LONG1 = 100;
const int BB_LONG2 = 200;
const int BB_LONG3 = 400;
const int BB_OFFSET = 2;
const int BB_DEV = 2;
const int RSI_LEN = 14;
const int RSI_UPPER = 70;
const int RSI_LOWER = 30;
const string SYMBOL = Symbol();

//--- indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
double myPoint; //initialized in OnInit


void myAlert(string type, string message) {
  // int handle;
  const string MSG_LABEL = " | BB-Range";
  if(type == "print") Print(message);
  else if(type == "error") Print(type + MSG_LABEL + SYMBOL + "," + IntegerToString(Period()) + " | "+message);
  else if(type == "indicator") {
    Print(type + MSG_LABEL + SYMBOL + "," + IntegerToString(Period()) + " | " + message );
    Alert(type + MSG_LABEL + SYMBOL + "," + IntegerToString(Period()) + " | " + message);
    SendNotification(type + MSG_LABEL + SYMBOL + "," + IntegerToString(Period()) + " | " + message);
  }
}


bool isDoublesEqual(double number1, double number2) { 
   if(NormalizeDouble(number1-number2,8)==0) return true;
   else return false;
}


void getOHLC(int candleIndex, double& results[]){
  double O = iOpen(SYMBOL, PERIOD_CURRENT, candleIndex);
  double H = iHigh(SYMBOL, PERIOD_CURRENT, candleIndex);
  double L = iLow(SYMBOL, PERIOD_CURRENT, candleIndex);
  double C = iClose(SYMBOL, PERIOD_CURRENT, candleIndex);
  ArrayFill(results, 0, 1, O);
  ArrayFill(results, 1, 1, H);
  ArrayFill(results, 2, 1, L);
  ArrayFill(results, 3, 1, C);
}

void getBands(int candleIndex, int BB_LEN, double& results[]){
  double UpperBB = iBands(SYMBOL, PERIOD_CURRENT, BB_LEN, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, candleIndex);
  double LowerBB = iBands(SYMBOL, PERIOD_CURRENT, BB_LEN, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, candleIndex);
  ArrayFill(results, 0, 1, UpperBB);
  ArrayFill(results, 1, 1, LowerBB);
}


bool isHittingBB(int candleIndex, int BB_LEN, bool hitUp){
  double originalBands[2];
  double offsetBands[2];
  getBands(candleIndex, BB_LEN, originalBands);
  getBands(candleIndex, (BB_LEN - BB_OFFSET), offsetBands);
  double OHLC[4];
  getOHLC(candleIndex, OHLC);
  bool isHit;
  if(hitUp) isHit = (OHLC[1] >= originalBands[0] && OHLC[2] <= originalBands[0]) || (OHLC[1] >= offsetBands[0] && OHLC[2] <= offsetBands[0]);
  else isHit = (OHLC[1] >= originalBands[1] && OHLC[2] <= originalBands[1]) || (OHLC[1] >= offsetBands[1] && OHLC[2] <= offsetBands[1]);
  return isHit;
}

bool isRSIValid(int candleIndex, bool hitUp){
  double RSI = iRSI(SYMBOL, PERIOD_CURRENT, RSI_LEN, PRICE_CLOSE, candleIndex);
  bool isValid;
  if(hitUp) isValid = MathCeil(RSI) >= RSI_UPPER;
  else isValid = MathFloor(RSI) <= RSI_LOWER;
  return isValid;
}


int OnInit() {   
  IndicatorBuffers(2);
  SetIndexBuffer(0, Buffer1);
  SetIndexEmptyValue(0, EMPTY_VALUE);
  SetIndexArrow(0, 241);
  SetIndexBuffer(1, Buffer2);
  SetIndexEmptyValue(1, EMPTY_VALUE);
  SetIndexArrow(1, 242);
  myPoint = Point();
  if(Digits() == 5 || Digits() == 3){
    myPoint *= 10;
  }
  return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[]) {
  int limit = rates_total - prev_calculated;
  ArraySetAsSeries(Buffer1, true);
  ArraySetAsSeries(Buffer2, true);
  if(prev_calculated < 1){
    ArrayInitialize(Buffer1, EMPTY_VALUE);
    ArrayInitialize(Buffer2, EMPTY_VALUE);
  }
  else limit++;
  
  for(int i = limit-1; i >= 0; i--) {
    if (i >= MathMin(5000-1, rates_total-1-50)) continue;

    // BB Values
    double BB_small_1_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_SHORT, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+1);
    double BB_small_1_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_SHORT, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+1);
    double BB_small_2_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_SHORT, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+2);
    double BB_small_2_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_SHORT, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+2);

    double BB_Long1_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG1, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+1);
    double BB_Long1_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG1, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+1);

    double BB_Long2_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG2, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+1);
    double BB_Long2_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG2, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+1);

    double BB_Long3_Upper = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG3, BB_DEV, 0, PRICE_CLOSE, MODE_UPPER, i+1);
    double BB_Long3_Lower = iBands(SYMBOL, PERIOD_CURRENT, BB_LONG3, BB_DEV, 0, PRICE_CLOSE, MODE_LOWER, i+1);


    // Candle Values
    double body1 = MathAbs(Close[i+1] - Open[i+1]);
    double body2 = MathAbs(Close[i+2] - Open[i+2]);
    double body1Top = MathMax(Open[i+1], Close[i+1]);
    double body2Top = MathMax(Open[i+2], Close[i+2]);
    double body1Bottom = MathMin(Open[i+1], Close[i+1]);
    double body2Bottom = MathMin(Open[i+2], Close[i+2]);
    double upperShadow1 = High[i+1] - body1Top;
    double upperShadow2 = High[i+2] - body2Top;
    double lowerShadow1 = body1Bottom - Low[i+1];
    double lowerShadow2 = body2Bottom - Low[i+2];

    // is 2CBB pattern Buy 
    bool isCurrentBullish = Close[i+1] > Open[i+1];
    bool isHigherClose = body1Top > body2Top;
    bool is2CBB_Buy = isCurrentBullish && isHigherClose;

    // is 2CBB pattern Sell 
    bool isCurrentBearish = Close[i+1] < Open[i+1];
    bool isLowerClose = body1Bottom < body2Bottom;
    bool is2CBB_Sell = isCurrentBearish && isLowerClose;

    // is the price hitting the Major BBs in the last 3 Candles
    bool isHittingTheBBL1Down = (isHittingBB(i+1, BB_LONG1, false) || isHittingBB(i+2, BB_LONG1, false));
    bool isHittingTheBBL1Up = (isHittingBB(i+1, BB_LONG1, true) || isHittingBB(i+2, BB_LONG1, true));
    bool isHittingTheBBL2Down = (isHittingBB(i+1, BB_LONG2, false) || isHittingBB(i+2, BB_LONG2, false));
    bool isHittingTheBBL2Up = (isHittingBB(i+1, BB_LONG2, true) || isHittingBB(i+2, BB_LONG2, true));
    bool isHittingTheBBL3Down = (isHittingBB(i+1, BB_LONG3, false) || isHittingBB(i+2, BB_LONG3, false));
    bool isHittingTheBBL3Up = (isHittingBB(i+1, BB_LONG3, true) || isHittingBB(i+2, BB_LONG3, true));

    bool isTheRSIValidForDown = (isRSIValid(i+1, false) || isRSIValid(i+2, false) );
    bool isTheRSIValidForUp = (isRSIValid(i+1, true) || isRSIValid(i+2, true) );

    bool isShortBBIncreasing = BB_small_1_Lower > BB_small_2_Lower;
    bool isShortBBDecreasing = BB_small_1_Lower < BB_small_2_Lower;

    bool isCloseAboveBB1 = Close[i+1] > BB_Long1_Lower;
    bool isCloseBelowBB1 = Close[i+1] < BB_Long1_Upper;
    bool isCloseAboveBB2 = Close[i+1] > BB_Long2_Lower;
    bool isCloseBelowBB2 = Close[i+1] < BB_Long2_Upper;
    bool isCloseAboveBB3 = Close[i+1] > BB_Long3_Lower;
    bool isCloseBelowBB3 = Close[i+1] < BB_Long3_Upper;

     // All Indicators Conditions Booleans
    bool isConditionBuyBB1 = isHittingTheBBL1Down && isCloseAboveBB1;
    bool isConditionSellBB1 = isHittingTheBBL1Up && isCloseBelowBB1;
    bool isConditionBuyBB2 = isHittingTheBBL2Down && isCloseAboveBB2;
    bool isConditionSellBB2 = isHittingTheBBL2Up && isCloseBelowBB2;
    bool isConditionBuyBB3 = isHittingTheBBL3Down && isCloseAboveBB3;
    bool isConditionSellBB3 = isHittingTheBBL3Up && isCloseBelowBB3;

    bool conditionBuy = (isConditionBuyBB1 || isConditionBuyBB2 || isConditionBuyBB3) && isTheRSIValidForDown && isShortBBIncreasing && is2CBB_Buy;
    bool conditionSell = (isConditionSellBB1 || isConditionSellBB2 || isConditionSellBB3) && isTheRSIValidForUp && isShortBBDecreasing && is2CBB_Sell;

    // arrows
    double ATR = iATR(SYMBOL, PERIOD_CURRENT, RSI_LEN, i+1);
    double distance = 0.3;
    double arrowMultUp = (Low[i+1] - (distance * ATR));
    double arrowMultDown = (High[i+1] + (distance * ATR));

    // for alert msg
    int currentContext;
    if(isConditionBuyBB1 || isConditionSellBB1) currentContext = BB_LONG1;
    else if(isConditionBuyBB2 || isConditionSellBB2) currentContext = BB_LONG2;
    else if(isConditionBuyBB3 || isConditionSellBB3) currentContext = BB_LONG3;

    if(conditionBuy) {
      Buffer1[i+1] = arrowMultUp;
      if(i == 0 && Time[0] != time_alert) myAlert("indicator", ALERT_MSG_BUY + currentContext); time_alert = Time[0];
    } else Buffer1[i] = EMPTY_VALUE;
    
    if(conditionSell){
      Buffer2[i+1] = arrowMultDown;
      if(i == 0 && Time[0] != time_alert) myAlert("indicator", ALERT_MSG_SELL + currentContext); time_alert = Time[0];
    } else Buffer2[i] = EMPTY_VALUE;

  }

  return(rates_total);
}
