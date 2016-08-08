//+------------------------------------------------------------------+
//|                                                   BaseSymbol.mq4 |
//|                                Copyright 2016, Chirita Alexandru |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2016, Chirita Alexandru"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#property copyright "Copyright � 2009, Ilnur (& Alexandru Chirita)"
#property link      "http://www.metaquotes.net"

#include <SymbolsLib.mqh>

class BaseSymbol
{
	protected:
		string SymbolsList[];
		
	public:
		BaseSymbol()
		{
			bool statusOk = true;
			statusOk = statusOk & (SymbolsList(SymbolsList, true) > 0);
			statusOk = statusOk & (SymbolsList(SymbolsList, false) > 0);
			
			if(!statusOk)
				Print("BaseSymbol initialisation is not ok! Hope it works!");
		}
		
		void PrintAllSymbols()
		{
			for(int i=0;i<ArraySize(SymbolsList);i++)
				Print(SymbolsList[i] + " " + SymbolDescription(SymbolsList[i]) + SymbolType(SymbolsList[i]));
		}
		
		bool SymbolExists(string symbolName)
		{
			for(int i=0;i<ArraySize(SymbolsList);i++)
				if(StringFind(SymbolsList[i], symbolName) != -1)
					return true;
			return false;
		}
		
		bool SymbolPartExists(string symbolName, bool isBaseSymbol = true)
		{
			int startingSymbolLength = isBaseSymbol ? 0 : 3; // base symbol starts from 0, second symbol starts from 3
			for(int i=0;i<ArraySize(SymbolsList);i++)
				if(StringSubstr(SymbolsList[i],startingSymbolLength,3) == symbolName)
					return true;
			return false;
		}
		
		void SymbolsListWithSymbolPart(string symbolName, string &baseSymbolList[], bool isBaseSymbol = true)
		{
			int startingSymbolLength = isBaseSymbol ? 0 : 3; // base symbol starts from 0, second symbol starts from 3
			int length = 0;
			for(int i=0;i<ArraySize(SymbolsList);i++)
				if(StringSubstr(SymbolsList[i],startingSymbolLength,3) == symbolName)
				{
					length++;
					ArrayResize(baseSymbolList,length);
					baseSymbolList[length-1] = SymbolsList[i];
				}
		}
		
};