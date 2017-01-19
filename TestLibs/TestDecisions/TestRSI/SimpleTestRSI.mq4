//+------------------------------------------------------------------+
//|                                                 SimpleTestBB.mq4 |
//|                                Copyright 2016, Chirita Alexandru |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Chirita Alexandru"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <MyMql/DecisionMaking/DecisionRSI.mqh>
#include <MyMql/UnOwnedTransactionManagement/FlowWithTrendTranMan.mqh>
#include <Files/FileTxt.mqh>
#include <MyMql/Global/Global.mqh>


int OnInit()
{
	// print some verbose info
	//VerboseInfo vi;
	//vi.BalanceAccountInfo();
	//vi.ClientAndTerminalInfo();
	//vi.PrintMarketInfo();
	
	GlobalContext.DatabaseLog.Initialize(true);
	GlobalContext.DatabaseLog.ParametersSet(__FILE__);
	GlobalContext.DatabaseLog.CallWebServiceProcedure("NewTradingSession");
	
	//if(IsTesting())
		return INIT_SUCCEEDED;
	//return ExpertValidationsTest(_Symbol);
}

void OnDeinit(const int reason)
{
	GlobalContext.DatabaseLog.ParametersSet(__FILE__);
	GlobalContext.DatabaseLog.CallWebServiceProcedure("EndTradingSession");
}


static FlowWithTrendTranMan transaction;

void OnTick()
{
	DecisionRSI decision;
	
	double SL = 0.0, TP = 0.0, spread = MarketInfo(_Symbol,MODE_ASK) - MarketInfo(_Symbol,MODE_BID), spreadPips = spread/Pip();
	
	//decision.SetVerboseLevel(1);
	//transaction.SetVerboseLevel(1);
	transaction.SetSimulatedOrderObjectName("SimulatedOrderRSI");
	transaction.SetSimulatedStopLossObjectName("SimulatedStopLossRSI");
	transaction.SetSimulatedTakeProfitObjectName("SimulatedTakeProfitRSI");
	
	transaction.AutoAddTransactionData(spreadPips);
	
	unsigned long type;
	double d = decision.GetDecision(0, type);
	
	// calculate profit/loss, TPs, SLs, etc
	transaction.CalculateData();
	double lots = MarketInfo(_Symbol, MODE_MINLOT); //GlobalContext.Money.GetLotsBasedOnDecision(d, false); -> to be moved
	
	if(d != IncertitudeDecision)
	{
		if(d > 0) { // Buy
			double price = MarketInfo(_Symbol,MODE_ASK); // Ask
			GlobalContext.Limit.CalculateTP_SL(TP, SL, 8*spreadPips, 13*spreadPips, OP_BUY, price, false, spread);
			if((TP != 0.0) || (SL != 0.0))
				GlobalContext.Limit.ValidateAndFixTPandSL(TP, SL, price, OP_BUY, spread, false);
			
			transaction.SimulateOrderSend(_Symbol, OP_BUY, 0.01, price, 0, SL, TP, NULL, 0, 0, clrNONE);
			int tichet = OrderSend(_Symbol, OP_BUY, 0.01, price, 0, SL, TP, NULL, 0, 0, clrAqua);
			
			if(tichet == -1)
				Print("Failed! Reason: " + IntegerToString(GetLastError()));
			
			//GlobalContext.DatabaseLog.DataLogDetail("NewOrder", "New order buy " + DoubleToStr(price) + " " + DoubleToStr(SL) + " " + DoubleToStr(TP));
			//GlobalContext.DatabaseLog.DataLogDetail("OrdersToString", transaction.OrdersToString(true));
		} else { // Sell
			double price = MarketInfo(_Symbol, MODE_BID); // Bid
			GlobalContext.Limit.CalculateTP_SL(TP, SL, 8*spreadPips, 13*spreadPips, OP_SELL, price, false, spread);
			if((TP != 0.0) || (SL != 0.0))
				GlobalContext.Limit.ValidateAndFixTPandSL(TP, SL, price, OP_SELL, spread, false);
			
			transaction.SimulateOrderSend(_Symbol, OP_SELL, 0.01, price, 0, SL, TP, NULL, 0, 0, clrNONE);
			int tichet = OrderSend(_Symbol, OP_SELL, 0.01, price, 0, SL, TP, NULL, 0, 0, clrChocolate);
			
			if(tichet == -1)
				Print("Failed! Reason: " + IntegerToString(GetLastError()));
			
			//GlobalContext.DatabaseLog.DataLogDetail("NewOrder", "New order sell " + DoubleToStr(price) + " " + DoubleToStr(SL) + " " + DoubleToStr(TP));
			//GlobalContext.DatabaseLog.DataLogDetail("OrdersToString", transaction.OrdersToString(true));
		}
		
		GlobalContext.Screen.ShowTextValue("CurrentValue", "Number of decisions: " + IntegerToString(transaction.GetNumberOfSimulatedOrders(-1)),clrGray, 20, 0);
		GlobalContext.Screen.ShowTextValue("CurrentValueSell", "Number of sell decisions: " + IntegerToString(transaction.GetNumberOfSimulatedOrders(OP_SELL)), clrGray, 20, 20);
		GlobalContext.Screen.ShowTextValue("CurrentValueBuy", "Number of buy decisions: " + IntegerToString(transaction.GetNumberOfSimulatedOrders(OP_BUY)), clrGray, 20, 40);
	}
	
	double profit, inverseProfit;
	int count, countNegative, countPositive, countInverseNegative, countInversePositive, irregularLimitsType;
	bool irregularLimits, isInverseDecision;
	transaction.GetBestTPandSL(TP, SL, profit, inverseProfit, count, countNegative, countPositive, countInverseNegative, countInversePositive, isInverseDecision, irregularLimits, irregularLimitsType);
	string summary = "Best profit: " + DoubleToString(profit,2) + " [IsInverseDecision: " + BoolToString(isInverseDecision) + "]"
		+ "\nBest Take profit: " + DoubleToString(TP,4) + " (spreadPips * " + DoubleToString(TP/spreadPips,2) + ")" 
		+ "\nBest Stop loss: " + DoubleToString(SL,4) + " (spreadPips * " + DoubleToString(SL/spreadPips,2) + ")"
		+ "\nIrregular Limits: " + BoolToString(irregularLimits) + " Type: " + IntegerToString(irregularLimitsType)
		+ "\nCount orders: " + IntegerToString(count) + " (" + IntegerToString(countPositive) + " positive orders & " + IntegerToString(countNegative) + " negative orders); Procentual profit: " + DoubleToString((double)countPositive*100/(count>0?(double)count:100),3) + "%"
		+ "\nCount inverse orders: " + IntegerToString(count) + " (" + IntegerToString(countInversePositive) + " inverse positive orders & " + IntegerToString(countInverseNegative) + " inverse negative orders); Procentual profit: " + DoubleToString((double)countInversePositive*100/(count>0?(double)count:100),3) + "%"
		//+ "\n\nMaximum profit (sum): " + DoubleToString(transaction.GetTotalMaximumProfitFromOrders(),2)
		//+ "\nMinimum profit (sum): " + DoubleToString(transaction.GetTotalMinimumProfitFromOrders(),2)
		//+ "\nMedium profit (avg): " + DoubleToString(transaction.GetTotalMediumProfitFromOrders(),2)
		+ "\n\nSpread: " + DoubleToString(spreadPips, 4)
		+ "\nTake profit / Spread (best from average): " + DoubleToString(TP/spreadPips,4)
		+ "\nStop loss / Spread (best from average): " + DoubleToString(SL/spreadPips,4);
	//GlobalContext.DatabaseLog.DataLog(decision.GetDecisionName() + " on " + _Symbol, summary);
	//Comment(summary);
	
	
	transaction.FlowWithTrend_UpdateSL_TP_UsingConstants(8*spreadPips, 13*spreadPips);
	GlobalContext.DatabaseLog.ParametersSet(__FILE__);
	GlobalContext.DatabaseLog.CallWebServiceProcedure("EndTradingSession");
}
