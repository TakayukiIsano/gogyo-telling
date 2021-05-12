package com.kodanukiware.first;

import ajd4jp.AJD;
import ajd4jp.Day;
import ajd4jp.STCD;
import ajd4jp.SexagenaryCycle;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import java.util.ArrayList;
import java.util.LinkedHashMap;

//Controllerだよ！という注釈
@Controller
public class HelloController {
  //RequestMapping "/"→ルートURLにアクセスすると呼び出されるようにできる
  //→アクセスするアドレスごとにメソッドを指定できる!
  @RequestMapping(value="/",method=RequestMethod.GET)
  //ModelとViewを2つとも置ける（返り値にできる）便利なやつ
  public ModelAndView index(ModelAndView mav) {
      //ビューネームの設定
      mav.setViewName("index");
      //値（msg）とそれに対する出力文字を設定
      mav.addObject("msg", "生年月日を入力してください：");
      return mav;
  }

  @RequestMapping(value="/",method=RequestMethod.POST)
  //"name"でPOSTされたパラメータを取得し、それを引数に
  public ModelAndView send(@RequestParam("name")String name,ModelAndView mav) {
	  String temp[] = name.split("-");
	  int year = Integer.parseInt(temp[0]);
	  int month = Integer.parseInt(temp[1]);
	  int day = Integer.parseInt(temp[2]);
	  AJD ajd = new AJD( year, month, day, 1, 0, 0 );							// 通常の暦
	  //LSCD lscd = LunisolarYear.getLunisolarYear( ajd ).getLSCD( ajd );	// 旧暦
      STCD stcd = new STCD( ajd );										// 節切り
	  mav.setViewName("index");
      mav.addObject("msg", print("暦:", stcd, year, month, day));
      //valueにname（入力値）を入れる
      mav.addObject("value",name);
      
      ArrayList<String> colors = makeParts(stcd, year, month, day);
      mav.setViewName("index");
      mav.addObject("kosei",kosei(colors));
      mav.addObject("hyoumen",hyoumen(colors));
      
      return mav;
  }
  
  private static String print(String title, Day date, int year1, int month1, int day1) {
      String  year = String.format("%d年(%s) ", year1,
              SexagenaryCycle.getYear(date));
      String  month = String.format("%2d月(%s) ", month1,
              SexagenaryCycle.getMonth(date));
      String  day = String.format("%2d日(%s) ", day1,
              SexagenaryCycle.getDay(date));
      return (title + year + month + day);
  }
  
  private static ArrayList<String> makeParts(Day date, int year1, int month1, int day1){
	  
	  ArrayList<String> temp = new ArrayList<String>();
	  String day =  SexagenaryCycle.getDay(date).toString();
	  temp.add(day.substring(0,1));
	  temp.add(day.substring(1,2));
	  String month = SexagenaryCycle.getMonth(date).toString();
	  temp.add(month.substring(1,2));
	  
	  return temp;
  }
  
  private static String kosei(ArrayList<String> colors) {
	  LinkedHashMap<String,String> map = new LinkedHashMap<>();
	  map.put("甲子", "RO");
	  map.put("甲戌", "YG");
	  map.put("甲申", "P");
	  map.put("甲午", "R");
	  map.put("甲辰", "B");
	  map.put("甲寅", "I");
	  
	  map.put("乙丑","B");
	  map.put("乙亥","R");
	  map.put("乙酉","P");
	  map.put("乙未","YG");
	  map.put("乙巳","RO");
	  map.put("乙卯","I");
	  
	  map.put("丙寅", "O");
	  map.put("丙子", "T");
	  map.put("丙戌", "G");
	  map.put("丙申", "M");
	  map.put("丙午", "BG");
	  map.put("丙辰", "Y");
	  
	  map.put("丁卯","M");
	  map.put("丁丑","G");
	  map.put("丁亥","T");
	  map.put("丁酉","O");
	  map.put("丁未","Y");
	  map.put("丁巳","BG");
	  
	  map.put("戊辰", "Y");
	  map.put("戊寅", "O");
	  map.put("戊子", "T");
	  map.put("戊戌", "G");
	  map.put("戊申", "M");
	  map.put("戊午", "BG");
	  
	  map.put("己巳", "BG");
	  map.put("己卯", "M");
	  map.put("己丑", "G");
	  map.put("己亥", "T");
	  map.put("己酉", "O");
	  map.put("己未", "Y");
	  
	  map.put("庚午", "RO");
	  map.put("庚辰", "YG");
	  map.put("庚寅", "P");
	  map.put("庚子", "R");
	  map.put("庚戌", "B");
	  map.put("庚申", "I");
	  
	  map.put("辛未", "B");
	  map.put("辛巳", "R");
	  map.put("辛卯", "P");
	  map.put("辛丑", "YG");
	  map.put("辛亥", "RO");
	  map.put("辛酉", "I");
	  
	  map.put("壬申", "O");
	  map.put("壬午", "T");
	  map.put("壬辰", "G");
	  map.put("壬寅", "M");
	  map.put("壬子", "BG");
	  map.put("壬戌", "Y");
	  
	  map.put("癸酉", "M");
	  map.put("癸未", "G");
	  map.put("癸巳", "T");
	  map.put("癸卯", "O");
	  map.put("癸丑", "Y");
	  map.put("癸亥", "BG");
	  
	  return map.get(colors.get(0) + colors.get(1));
  }
  
  private static String hyoumen(ArrayList<String> colors) {
	  
	  String month = colors.get(2);
	  String day = colors.get(0);
	  
	  int day_i = 0;
	  
	  switch(day) {
	  case "甲":
		  day_i = 0;
	  break;
	  
	  case "乙":
		  day_i = 1;
	  break;
	  
	  case "丙":
		  day_i = 2;
	  break;
	  
	  case "丁":
		  day_i = 3;
	  break;
	  
	  case "戊":
		  day_i = 4;
	  break;
	  
	  case "己":
		  day_i = 5;
	  break;
	  
	  case "庚":
		  day_i = 6;
	  break;
	  
	  case "辛":
		  day_i = 7;
	  break;
	  
	  case "壬":
		  day_i = 8;
	  break;
	  
	  case "癸":
		  day_i = 9;
	  break;
	  
	  }
	  /*
	   * ＊支ー子丑寅卯辰巳午未申酉戌亥
	   */
	    
	  
	  String[] one = {"Y","B","YG","G","YG","G","G","YG","B","Y"};
	  String[] two = {"I","BG","O","R","O","R","P","T","M","RO"};
	  String[] three = {"BG","I","RO","M","RO","M","T","P","R","O"};
	  String[] four = {"B","Y","Y","B","Y","B","YG","G","G","YG"};
	  String[] five = {"M","RO","I","BG","I","BG","O","R","P","T"};
	  String[] six = {"R","O","BG","I","BG","I","RO","M","T","P"};
	  String[] seven = {"G","YG","B","Y","B","Y","Y","B","YG","G"};
	  String[] eight = {"P","T","M","RO","M","RO","I","BG","O","R"};
	  String[] nine = {"T","P","R","O","R","O","BG","I","RO","M"};
	  String[] ten = {"YG","G","G","YG","G","YG","B","Y","Y","B"};
	  String[] eleven = {"O","R","P","T","P","T","M","RO","I","BG"};
	  String[] twoeleve = {"RO","M","T","P","T","P","R","O","BG","I"};
	  
	  
	  switch(month) {
	  case "丑":
		  return one[day_i];
		  
	  case "寅":
		  return two[day_i];
		  
	  case "卯":
		  return three[day_i];
		  
	  case "辰":
		  return four[day_i];
		  
	  case "巳":
		  return five[day_i];
		  
	  case "午":
		  return six[day_i];
		  
	  case "未":
		  return seven[day_i];
		  
	  case "申":
		  return eight[day_i];
		  
	  case "酉":
		  return nine[day_i];
		  
	  case "戌":
		  return ten[day_i];
		  
	  case "亥":
		  return eleven[day_i];
		  
	  case "子":
		  return twoeleve[day_i];
	 
	  }
	  

	  
	  return null;
	  
  }

}