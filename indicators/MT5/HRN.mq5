//+------------------------------------------------------------------+
//|                                           Indicator: HRN-MT5.mq5 |
//|                                       Created with EABuilder.com |
//|                                        https://www.eabuilder.com |
//+------------------------------------------------------------------+
#property copyright "Created with EABuilder.com"
#property link      "https://www.eabuilder.com"
#property version   "1.00"
#property description ""

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 5
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy HRN"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 5
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell HRN"

//--- indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
input bool Audible_Alerts = true;
input bool Push_Notifications = true;
double myPoint; //initialized in OnInit
int MA8_HANDLE;
double MA8[];
int MA20_HANDLE;
double MA20[];
int MA50_HANDLE;
double MA50[];

int MA7_HANDLE;
double MA7[];
int MA19_HANDLE;
double MA19[];
int MA49_HANDLE;
double MA49[];

int RSI_HANDLE;
double RSI[];


double Open[];
double Close[];
double High[];
double Low[];

void myAlert(string type, string message) {
  // int handle;
  const string MSG_LABEL = " | HRN Pattern ";
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
      if(context == 8) msg = "Buy HRN MA8";
      else if(context == 20) msg = "Buy HRN MA20";
      else if(context == 50) msg = "Buy HRN MA50";
    } else {
      if(context == 8) msg = "Sell HRN MA8";
      else if(context == 20) msg = "Sell HRN MA20";
      else if(context == 50) msg = "Sell HRN MA50";
    }

    return msg;
}


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_ARROW, 241);
   SetIndexBuffer(1, Buffer2);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(1, PLOT_ARROW, 242);
   //initialize myPoint
   myPoint = Point();

   if(Digits() == 5 || Digits() == 3) { myPoint *= 10; }
   
   // MA, RSI
   MA8_HANDLE = iMA(NULL, PERIOD_CURRENT, 8, 0, MODE_SMA, PRICE_CLOSE);
   MA20_HANDLE = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
   MA50_HANDLE = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE);
   // approximation MA
   MA7_HANDLE = iMA(NULL, PERIOD_CURRENT, 7, 0, MODE_SMA, PRICE_CLOSE);
   MA19_HANDLE = iMA(NULL, PERIOD_CURRENT, 19, 0, MODE_SMA, PRICE_CLOSE);
   MA49_HANDLE = iMA(NULL, PERIOD_CURRENT, 49, 0, MODE_SMA, PRICE_CLOSE);
   RSI_HANDLE = iRSI(NULL, PERIOD_CURRENT, 14, PRICE_CLOSE);
   
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
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   ArraySetAsSeries(Buffer2, true);
   //--- initial zero
   if (prev_calculated < 1) {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
      ArrayInitialize(Buffer2, EMPTY_VALUE);
    }
   else limit++;
   datetime Time[];


   if(BarsCalculated(MA8_HANDLE) <= 0)  return(0);
   if(CopyBuffer(MA8_HANDLE, 0, 0, rates_total, MA8) <= 0) return(rates_total);
   ArraySetAsSeries(MA8, true);

   if(BarsCalculated(MA20_HANDLE) <= 0)  return(0);
   if(CopyBuffer(MA20_HANDLE, 0, 0, rates_total, MA20) <= 0) return(rates_total);
   ArraySetAsSeries(MA20, true);

   if(BarsCalculated(MA50_HANDLE) <= 0)  return(0);
   if(CopyBuffer(MA50_HANDLE, 0, 0, rates_total, MA50) <= 0) return(rates_total);
   ArraySetAsSeries(MA50, true);

   if(BarsCalculated(MA7_HANDLE) <= 0)  return(0);
   if(CopyBuffer(MA7_HANDLE, 0, 0, rates_total, MA7) <= 0) return(rates_total);
   ArraySetAsSeries(MA7, true);

   if(BarsCalculated(MA19_HANDLE) <= 0)  return(0);
   if(CopyBuffer(MA19_HANDLE, 0, 0, rates_total, MA19) <= 0) return(rates_total);
   ArraySetAsSeries(MA19, true);

   if(BarsCalculated(MA49_HANDLE) <= 0)  return(0);
   if(CopyBuffer(MA49_HANDLE, 0, 0, rates_total, MA49) <= 0) return(rates_total);
   ArraySetAsSeries(MA49, true);

   if(BarsCalculated(RSI_HANDLE) <= 0)  return(0);
   if(CopyBuffer(RSI_HANDLE, 0, 0, rates_total, RSI) <= 0) return(rates_total);
   ArraySetAsSeries(RSI, true);


   if(CopyOpen(Symbol(), PERIOD_CURRENT, 0, rates_total, Open) <= 0) return(rates_total);
   ArraySetAsSeries(Open, true);
   if(CopyClose(Symbol(), PERIOD_CURRENT, 0, rates_total, Close) <= 0) return(rates_total);
   ArraySetAsSeries(Close, true);
   if(CopyHigh(Symbol(), PERIOD_CURRENT, 0, rates_total, High) <= 0) return(rates_total);
   ArraySetAsSeries(High, true);
   if(CopyLow(Symbol(), PERIOD_CURRENT, 0, rates_total, Low) <= 0) return(rates_total);
   ArraySetAsSeries(Low, true);
   if(CopyTime(Symbol(), Period(), 0, rates_total, Time) <= 0) return(rates_total);
   ArraySetAsSeries(Time, true);




   //--- main loop
   for(int i = limit-1; i >= 0; i--) {
    if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation
    // MA comparison & RSI Validation
    bool isUptrend = MA8[i+1] > MA20[i+1] && MA20[i+1] > MA50[i+1] && MA8[i+2] > MA20[i+2] && MA20[i+2] > MA50[i+2] && MA8[i+3] > MA20[i+3] && MA20[i+3] > MA50[i+3];
    bool isUptrendFor50 = MA20[i+1] > MA50[i+1] && MA20[i+2] > MA50[i+2] && MA20[i+3] > MA50[i+3];
    bool isDowntrend = MA8[i+1] < MA20[i+1] && MA20[i+1] < MA50[i+1] && MA8[i+2] < MA20[i+2] && MA20[i+2] < MA50[i+2] && MA8[i+3] < MA20[i+3] && MA20[i+3] < MA50[i+3];
    bool isDowntrendFor50 = MA20[i+1] < MA50[i+1] && MA20[i+2] < MA50[i+2] && MA20[i+3] < MA50[i+3];
    bool RSIValidationUptrend = RSI[i+1] < 70;
    bool RSIValidationDowntrend = RSI[i+1] > 30;
    // MAs increasing in value
    bool isMAsIncreasing = MA8[i+1] > MA8[i+2] && MA8[i+2] > MA8[i+3] && MA20[i+1] > MA20[i+2] && MA20[i+2] > MA20[i+3] && MA50[i+1] > MA50[i+2] && MA50[i+2] > MA50[i+3];
    bool isMAsIncreasingFor50 = MA20[i+1] > MA20[i+2] && MA20[i+2] > MA20[i+3] && MA50[i+1] > MA50[i+2] && MA50[i+2] > MA50[i+3];
    bool isMAsDecreasing = MA8[i+1] < MA8[i+2] && MA8[i+2] < MA8[i+3] && MA20[i+1] < MA20[i+2] && MA20[i+2] < MA20[i+3] && MA50[i+1] < MA50[i+2] && MA50[i+2] < MA50[i+3];
    bool isMAsDecreasingFor50 = MA20[i+1] < MA20[i+2] && MA20[i+2] < MA20[i+3] && MA50[i+1] < MA50[i+2] && MA50[i+2] < MA50[i+3];
    // is either of the candles are in contact with the MA (approximation -2), in order to detect a Pullback on the MA
    bool isHitting1 = (MA8[i+1] <= High[i+1] && MA8[i+1] >= Low[i+1]) || (MA7[i+1] <= High[i+1] && MA7[i+1] >= Low[i+1]);
    bool isHitting2 = (MA8[i+2] <= High[i+2] && MA8[i+2] >= Low[i+2]) || (MA7[i+2] <= High[i+2] && MA7[i+2] >= Low[i+2]);
    bool isHitting3 = (MA8[i+3] <= High[i+3] && MA8[i+3] >= Low[i+3]) || (MA7[i+3] <= High[i+3] && MA7[i+3] >= Low[i+3]);
    bool isHittingMA8 = isHitting1 || isHitting2 || isHitting3;
    bool isHitting4 = (MA20[i+1] <= High[i+1] && MA20[i+1] >= Low[i+1]) || (MA19[i+1] <= High[i+1] && MA19[i+1] >= Low[i+1]);
    bool isHitting5 = (MA20[i+2] <= High[i+2] && MA20[i+2] >= Low[i+2]) || (MA19[i+2] <= High[i+2] && MA19[i+2] >= Low[i+2]);
    bool isHitting6 = (MA20[i+3] <= High[i+3] && MA20[i+3] >= Low[i+3]) || (MA19[i+3] <= High[i+3] && MA19[i+3] >= Low[i+3]);
    bool isHittingMA20 = isHitting4 || isHitting5 || isHitting6;
    bool isHitting7 = (MA50[i+1] <= High[i+1] && MA50[i+1] >= Low[i+1]) || (MA49[i+1] <= High[i+1] && MA49[i+1] >= Low[i+1]);
    bool isHitting8 = (MA50[i+2] <= High[i+2] && MA50[i+2] >= Low[i+2]) || (MA49[i+2] <= High[i+2] && MA49[i+2] >= Low[i+2]);
    bool isHitting9 = (MA50[i+3] <= High[i+3] && MA50[i+3] >= Low[i+3]) || (MA49[i+3] <= High[i+3] && MA49[i+3] >= Low[i+3]);
    bool isHittingMA50 = isHitting7 || isHitting8 || isHitting9;

    // All Indicators Conditions Boolean
    bool isConditionMetUptrend = isUptrend && isMAsIncreasing && RSIValidationUptrend;
    bool isConditionMetUptrendFor50 = isUptrendFor50 && isMAsIncreasingFor50 && RSIValidationUptrend;
    bool isConditionMetDowntrend = isDowntrend && isMAsDecreasing && RSIValidationDowntrend;
    bool isConditionMetDowntrendFor50 = isDowntrendFor50 && isMAsDecreasingFor50 && RSIValidationDowntrend;

    // is HRN Pattern Buy
    bool is3rdBear = Open[i+3] > Close[i+3];
    bool isPrevBear = Open[i+2] > Close[i+2];
    bool isCurrentBull = Open[i+1] < Close[i+1];
    bool isOHCL3BiggerThan2 = MathMax(Open[i+3],Close[i+3]) > MathMax(Open[i+2],Close[i+2]) && MathMin(Open[i+3],Close[i+3]) > MathMin(Open[i+2],Close[i+2]) && High[i+3] > High[i+2] && Low[i+3] > Low[i+2];
    bool isHigherClose = Close[i+1] >= MathMax(Open[i+2],Close[i+2]);
    bool isHigherOpen = Open[i+1] >= MathMin(Open[i+2],Close[i+2]);
    bool isHigherShadow = High[i+1] >= High[i+2];
    double body1 = MathAbs(Close[i+1] - Open[i+1]);
    double body2 = MathAbs(Close[i+2] - Open[i+2]);
    double upperShadow1 = High[i+1] - MathMax(Open[i+1], Close[i+1]);
    double upperShadow2 = High[i+2] - MathMax(Open[i+2], Close[i+2]);
    bool isUpperShadowsSmallerThanBodies = upperShadow1 < body1 && upperShadow2 < body2;
    bool isCloseAbove8 = Close[i+1] > MA8[i+1];
    bool isCloseAbove20 = Close[i+1] > MA20[i+1];
    bool isCloseAbove50 = Close[i+1] > MA50[i+1];
    bool isHRNBuyPattern = is3rdBear && isPrevBear && isCurrentBull && isOHCL3BiggerThan2 && isHigherClose && isHigherOpen && isHigherShadow && isUpperShadowsSmallerThanBodies;
    bool isHRNBuy8 = isHRNBuyPattern && isCloseAbove8;
    bool isHRNBuy20 = isHRNBuyPattern && isCloseAbove20;
    bool isHRNBuy50 = isHRNBuyPattern && isCloseAbove50;

     // is HRN Pattern Sell
    bool is3rdBull = Open[i+3] < Close[i+3];
    bool isPrevBull = Open[i+2] < Close[i+2];
    bool isCurrentBear = Open[i+1] > Close[i+1];
    bool isOHCL3LowerThan2 = MathMax(Open[i+3],Close[i+3]) < MathMax(Open[i+2],Close[i+2]) && MathMin(Open[i+3],Close[i+3]) < MathMin(Open[i+2],Close[i+2]) && High[i+3] < High[i+2] && Low[i+3] < Low[i+2];
    bool isLowerClose = Close[i+1] <= MathMin(Open[i+2],Close[i+2]);
    bool isLowerOpen = Open[i+1] <= MathMax(Open[i+2],Close[i+2]);
    bool isLowerShadow = Low[i+1] <= Low[i+2];
    double body1S = MathAbs(Close[i+1] - Open[i+1]);
    double body2S = MathAbs(Close[i+2] - Open[i+2]);
    double lowerShadow1 = MathMin(Open[i+1], Close[i+1]) - Low[i+1];
    double lowerShadow2 = MathMin(Open[i+2], Close[i+2]) - Low[i+2];
    bool isLowerShadowsSmallerThanBodies = lowerShadow1 < body1S && lowerShadow2 < body2S;
    bool isCloseBelow8 = Close[i+1] < MA8[i+1];
    bool isCloseBelow20 = Close[i+1] < MA20[i+1];
    bool isCloseBelow50 = Close[i+1] < MA50[i+1];
    bool isHRNSellPattern = is3rdBull && isPrevBull && isCurrentBear && isOHCL3LowerThan2 && isLowerClose && isLowerOpen && isLowerShadow && isLowerShadowsSmallerThanBodies;
    bool isHRNSell8 = isHRNSellPattern && isCloseBelow8;
    bool isHRNSell20 = isHRNSellPattern && isCloseBelow20;
    bool isHRNSell50 = isHRNSellPattern && isCloseBelow50;



    // final conditions
    bool conditionUptrend8 = isConditionMetUptrend && isHittingMA8 && isHRNBuy8;
    bool conditionUptrend20 = isConditionMetUptrend && isHittingMA20 && isHRNBuy20;
    bool conditionUptrend50 = isConditionMetUptrendFor50 && isHittingMA50 && isHRNBuy50;
    bool conditionDowntrend8 = isConditionMetDowntrend && isHittingMA8 && isHRNSell8;
    bool conditionDowntrend20 = isConditionMetDowntrend && isHittingMA20 && isHRNSell20;
    bool conditionDowntrend50 = isConditionMetDowntrendFor50 && isHittingMA50 && isHRNSell50;

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
//+------------------------------------------------------------------+