#property copyright "Created By Ali Sawari"
#property version   "1.00"
#property description ""

#include <stdlib.mqh>
#include <stderror.mqh>

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 5
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy Engulfing"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 5
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell Engulfing"


//--- indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
extern bool Audible_Alerts = true;
extern bool Push_Notifications = true;
double myPoint; //initialized in OnInit

void myAlert(string type, string message) {
  // int handle;
  const string MSG_LABEL = " | Engulfing Pattern ";
  if(type == "print") Print(message);
  else if(type == "error") Print(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | "+message);
  else if(type == "indicator") {
    Print(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message );
    if(Audible_Alerts) Alert(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message);
    if(Push_Notifications) SendNotification(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message);
  }
}

string getCorrectMSG(bool uptrend, int context){
    string msg;
    if(uptrend){
      if(context == 8) msg = "Buy Engulfing MA8";
      else if(context == 20) msg = "Buy Engulfing MA20";
      else if(context == 50) msg = "Buy Engulfing MA50";
    } else {
      if(context == 8) msg = "Sell Engulfing MA8";
      else if(context == 20) msg = "Sell Engulfing MA20";
      else if(context == 50) msg = "Sell Engulfing MA50";
    }

    return msg;
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {   
  IndicatorBuffers(2);
  SetIndexBuffer(0, Buffer1);
  SetIndexEmptyValue(0, EMPTY_VALUE);
  SetIndexArrow(0, 241);
  SetIndexBuffer(1, Buffer2);
  SetIndexEmptyValue(1, EMPTY_VALUE);
  SetIndexArrow(1, 242);
  //initialize myPoint
  myPoint = Point();
  if(Digits() == 5 || Digits() == 3){
    myPoint *= 10;
  }
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
  //--- counting from 0 to rates_total
  ArraySetAsSeries(Buffer1, true);
  ArraySetAsSeries(Buffer2, true);
  //--- initial zero
  if(prev_calculated < 1){
    ArrayInitialize(Buffer1, EMPTY_VALUE);
    ArrayInitialize(Buffer2, EMPTY_VALUE);
  }
  else limit++;
  
  //--- main loop
  for(int i = limit-1; i >= 0; i--) {
    if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation
    // Main MAs & RSI
    float MA8_1 = iMA(NULL, PERIOD_CURRENT, 8, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA8_2 = iMA(NULL, PERIOD_CURRENT, 8, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float MA20_1 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA20_2 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float MA50_1 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA50_2 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float RSI = iRSI(NULL, PERIOD_CURRENT, 14, PRICE_CLOSE, 1+i);
    // Approximation MAs for Better PB Detection
    float MA7_1 = iMA(NULL, PERIOD_CURRENT, 7, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA7_2 = iMA(NULL, PERIOD_CURRENT, 7, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float MA18_1 = iMA(NULL, PERIOD_CURRENT, 18, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA18_2 = iMA(NULL, PERIOD_CURRENT, 18, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float MA48_1 = iMA(NULL, PERIOD_CURRENT, 48, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA48_2 = iMA(NULL, PERIOD_CURRENT, 48, 0, MODE_SMA, PRICE_CLOSE, i+2);
    // MA comparison & RSI Validation
    bool isUptrend = MA8_1 > MA20_1 && MA20_1 > MA50_1 && MA8_2 > MA20_2 && MA20_2 > MA50_2;
    bool isUptrendFor50 = MA20_1 > MA50_1 && MA20_2 > MA50_2;
    bool isDowntrend = MA8_1 < MA20_1 && MA20_1 < MA50_1 && MA8_2 < MA20_2 && MA20_2 < MA50_2;
    bool isDowntrendFor50 = MA20_1 < MA50_1 && MA20_2 < MA50_2;
    bool RSIValidationUptrend = RSI < 70;
    bool RSIValidationDowntrend = RSI > 30;
    // MAs increasing in value
    bool isMAsIncreasing = MA8_1 > MA8_2 && MA20_1 > MA20_2 && MA50_1 > MA50_2;
    bool isMAsIncreasingFor50 = MA20_1 > MA20_2 && MA50_1 > MA50_2;
    bool isMAsDecreasing = MA8_1 < MA8_2 && MA20_1 < MA20_2 && MA50_1 < MA50_2;
    bool isMAsDecreasingFor50 = MA20_1 < MA20_2 && MA50_1 < MA50_2;
    // is either of the candles are in contact with the MA (approximation -2), in order to detect a Pullback on the MA
    bool isHitting1 = (MA8_1 <= High[i+1] && MA8_1 >= Low[i+1]) || (MA7_1 <= High[i+1] && MA7_1 >= Low[i+1]);
    bool isHitting2 = (MA8_2 <= High[i+2] && MA8_2 >= Low[i+2]) || (MA7_2 <= High[i+2] && MA7_2 >= Low[i+2]);
    bool isHittingMA8 = isHitting1 || isHitting2;
    bool isHitting3 = (MA20_1 <= High[i+1] && MA20_1 >= Low[i+1]) || (MA18_1 <= High[i+1] && MA18_1 >= Low[i+1]);
    bool isHitting4 = (MA20_2 <= High[i+2] && MA20_2 >= Low[i+2]) || (MA18_2 <= High[i+2] && MA18_2 >= Low[i+2]);
    bool isHittingMA20 = isHitting3 || isHitting4;
    bool isHitting5 = (MA50_1 <= High[i+1] && MA50_1 >= Low[i+1]) || (MA48_1 <= High[i+1] && MA48_1 >= Low[i+1]);
    bool isHitting6 = (MA50_2 <= High[i+2] && MA50_2 >= Low[i+2]) || (MA48_2 <= High[i+2] && MA48_2 >= Low[i+2]);
    bool isHittingMA50 = isHitting5 || isHitting6;

    // All Indicators Conditions Boolean
    bool isConditionMetUptrend = isUptrend && isMAsIncreasing && RSIValidationUptrend;
    bool isConditionMetUptrendFor50 = isUptrendFor50 && isMAsIncreasingFor50 && RSIValidationUptrend;
    bool isConditionMetDowntrend = isDowntrend && isMAsDecreasing && RSIValidationDowntrend;
    bool isConditionMetDowntrendFor50 = isDowntrendFor50 && isMAsDecreasingFor50 && RSIValidationDowntrend;

    // is Engulfing Pattern Buy
    bool isPrevBear = Open[i+2] > Close[i+2];
    bool isCurrentBull = Open[i+1] < Close[i+1];
    bool isEngulfingBodyB = Close[i+1] >= Open[i+2] && Open[i+1] <= Close[i+2];
    bool isEngulfingShadow = High[i+1] >= High[i+2] && Low[i+1] <= Low[i+2];
    float body1 = MathAbs(Close[i+1] - Open[i+1]);
    float body2 = MathAbs(Close[i+2] - Open[i+2]);
    float upperShadow1 = High[i+1] - MathMax(Open[i+1], Close[i+1]);
    float upperShadow2 = High[i+2] - MathMax(Open[i+2], Close[i+2]);
    bool isUpperShadowsSmallerThanBodies = upperShadow1 < body1 && upperShadow2 < body2;
    bool isCloseAbove8 = Close[i+1] > MA8_1;
    bool isCloseAbove20 = Close[i+1] > MA20_1;
    bool isCloseAbove50 = Close[i+1] > MA50_1;
    bool isEngulfingBuyPattern = isPrevBear && isCurrentBull && isEngulfingBodyB && isEngulfingShadow && isUpperShadowsSmallerThanBodies;
    bool isEngulfingBuy8 = isEngulfingBuyPattern && isCloseAbove8;
    bool isEngulfingBuy20 = isEngulfingBuyPattern && isCloseAbove20;
    bool isEngulfingBuy50 = isEngulfingBuyPattern && isCloseAbove50;

    // is Engulfing Pattern Sell
    bool isPrevBull = Open[i+2] < Close[i+2];
    bool isCurrentBear = Open[i+1] > Close[i+1];
    bool isEngulfingBodyS = Close[i+1] <= Open[i+2] && Open[i+1] >= Close[i+2];
    float lowerShadow1 = MathMin(Open[i+1], Close[i+1]) - Low[i+1];
    float lowerShadow2 = MathMin(Open[i+2], Close[i+2]) - Low[i+2];
    bool isLowerShadowsSmallerThanBodies = lowerShadow1 < body1 && lowerShadow2 < body2;
    bool isCloseBelowMA8 = Close[i+1] < MA8_1;
    bool isCloseBelowMA20 = Close[i+1] < MA20_1;
    bool isCloseBelowMA50 = Close[i+1] < MA50_1;
    bool isEngulfingSellPattern = isPrevBull && isCurrentBear && isEngulfingBodyS && isEngulfingShadow && isLowerShadowsSmallerThanBodies;
    bool isEngulfingSell8 = isEngulfingSellPattern && isCloseBelowMA8;
    bool isEngulfingSell20 = isEngulfingSellPattern && isCloseBelowMA20;
    bool isEngulfingSell50 = isEngulfingSellPattern && isCloseBelowMA50;



    // final conditions
    bool conditionUptrend8 = isConditionMetUptrend && isHittingMA8 && isEngulfingBuy8;
    bool conditionUptrend20 = isConditionMetUptrend && isHittingMA20 && isEngulfingBuy20;
    bool conditionUptrend50 = isConditionMetUptrendFor50 && isHittingMA50 && isEngulfingBuy50;
    bool conditionDowntrend8 = isConditionMetDowntrend && isHittingMA8 && isEngulfingSell8;
    bool conditionDowntrend20 = isConditionMetDowntrend && isHittingMA20 && isEngulfingSell20;
    bool conditionDowntrend50 = isConditionMetDowntrendFor50 && isHittingMA50 && isEngulfingSell50;

    bool conditionUptrend = conditionUptrend8 || conditionUptrend20 || conditionUptrend50;
    bool conditionDowntrend = conditionDowntrend8 || conditionDowntrend20 || conditionDowntrend50;

    // for alert msg
    int currentContext;
    if(conditionUptrend8 || conditionDowntrend8) currentContext = 8;
    else if(conditionUptrend20 || conditionDowntrend20) currentContext = 20;
    else if(conditionUptrend50 || conditionDowntrend50) currentContext = 50;

    if(conditionUptrend) {
      Buffer1[i] = Low[1+i];
      string msgBuy = getCorrectMSG(true, currentContext);
      if(i == 0 && Time[0] != time_alert) myAlert("indicator", msgBuy); time_alert = Time[0];
    } else Buffer1[i] = EMPTY_VALUE;
    
    if(conditionDowntrend){
      Buffer2[i] = High[1+i];
      string msgSell = getCorrectMSG(false, currentContext);
      if(i == 0 && Time[0] != time_alert) myAlert("indicator", msgSell); time_alert = Time[0];
    } else Buffer2[i] = EMPTY_VALUE;

  }

  return(rates_total);
}
