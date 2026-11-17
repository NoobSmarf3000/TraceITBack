extends Resource
class_name JavaFauxSyntax

const PATCH_LEVEL := 5   



const DEFAULT_SLOT_WIDTH := 70
const DEFAULT_FILE := "Main.java"

const ERROR_TYPES := ["COMPILE", "RUNTIME", "LOGICAL"]
const CHALLENGE_TYPES := ["slots", "find_line", "order", "predict", "classify", "trace"]

const DEFAULT_INSTRUCTIONS := (
	"1. Solve every sub-puzzle in one life\n"
	+ "2. 7 mistakes costs a life.\n"
	+ "Lose all 3 and there's consequences"
)

const CURRICULUM := {
	1: {"title": "Hello World", "chapters": ["Get Started", "Syntax", "Output", "Comments"]},
	2: {"title": "Letters and Numbers", "chapters": ["Variables", "Data Types", "Operators"]},
	3: {"title": "Strings, Math & Booleans", "chapters": ["Strings", "Math", "Booleans"]},
	4: {"title": "Conditions", "chapters": ["If", "Else", "Else If", "Switch"]},
	5: {"title": "While Loops", "chapters": ["While Loop", "Do/While Loop"]},
	6: {"title": "For Loops", "chapters": ["For Loop", "Nested Loops"]},
	7: {"title": "Trace It Back", "chapters": ["Everything above, as one program"]},
}


const INTRO_QUIZ := [
	{
		"question": "In which year was Java created?",
		"options": ["1985", "1995", "2004", "2010"],
		"answer": 1,
		"fact": "Java is a popular programming language, created in 1995.",
	},
	{
		"question": "Who owns Java?",
		"options": ["Google", "Microsoft", "Oracle", "Apple"],
		"answer": 2,
		"fact": "Java is owned by Oracle.",
	},
	{
		"question": "How many devices run Java?",
		"options": ["More than 3 billion", "About 300 million", "Around 3 million", "Under 1 million"],
		"answer": 0,
		"fact": "More than 3 billion devices run Java.",
	},
	{
		"question": "Which of these is NOT something Java is used for?",
		"options": ["Mobile apps (Android)", "Games", "Database connection", "Styling pages with CSS"],
		"answer": 3,
		"fact": "Java is used for mobile, desktop and web apps, servers, games and database connection.",
	},
	{
		"question": "Which platforms does Java work on?",
		"options": ["Windows, Mac, Linux, Raspberry Pi", "Windows only", "Android only", "Linux only"],
		"answer": 0,
		"fact": "Java works on different platforms: Windows, Mac, Linux, Raspberry Pi and more.",
	},
	{
		"question": "Which command compiles Main.java?",
		"options": ["javac Main.java", "java Main", "run Main.java", "compile Main"],
		"answer": 0,
		"fact": "javac Main.java compiles the code. Then java Main runs it.",
	},
]

const PUZZLES := {
	1: {
		"title": "Hello World",
		"steps": [
			{
				"type": "slots",
				"topic": "Get Started",
				"title": "Get Started",
				"file": "Main.java",
				"lines": [
					"public class <<cls:70>> {",
					"  public static void <<method:70>>(String[] args) {",
					"    System.out.println(<<text:120>>)<<semi:30>>",
					"  }",
					"}",
				],
				"answers": {
					"cls": "Main",
					"method": "main",
					"text": "\"Hello World\"",
					"semi": ";",
				},
				"decoys": ["Program", "start"],
				"types": {
					"method": "RUNTIME",
				},
				"errors": {
					"cls": "class %s is public, should be declared in a file named %s.java",
					"method": "no entry point found: '%s' is never run",
					"semi": "';' expected",
				},
				"empty_errors": {
					"cls": {"type": "COMPILE", "text": "<identifier> expected"},
					"method": {"type": "COMPILE", "text": "<identifier> expected"},
					"text": {"type": "LOGICAL", "text": "the program printed an empty line"},
				},
				"string_slots": ["text"],
				"typed_errors": {
					"text": {
						"Hello World": "')' or ',' expected",
					},
				},
				"output": "Hello World",
			},

			{
				"type": "find_line",
				"topic": "Syntax",
				"title": "Syntax",
				"prompt": "The compiler reports:\n  error: package system does not exist\nClick the line it is complaining about, then Submit.",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    system.out.println(\"Hello World\");",
					"  }",
					"}",
				],
				"faulty": [3],
				"multi": false,
				"error_type": "COMPILE",
				"wrong_text": "no error found on this line",
				"output": "Hello World",
			},

			{
				"type": "order",
				"topic": "Statements",
				"title": "Statements",
				"prompt": "Statements run one by one, top to bottom.\nOrder them so the program prints: Booting, Loading, Ready",
				"lines": [
					"System.out.println(\"Booting\");",
					"System.out.println(\"Loading\");",
					"System.out.println(\"Ready\");",
				],
				"start_order": [2, 0, 1],
				"error_type": "LOGICAL",
				"wrong_text": "this statement runs at the wrong time",
				"output": "Booting\nLoading\nReady",
			},

			{
				"type": "predict",
				"topic": "Output, Print Numbers",
				"title": "Output",
				"prompt": "Read the program, then pick what it prints.",
				"lines": [
					"System.out.print(\"A\");",
					"System.out.println(\"B\");",
					"System.out.println(2 + 3);",
				],
				"question": "What does it print?",
				"options": [
					"AB, then 5 on the next line",
					"A, B and 5 on three lines",
					"AB5 on a single line",
					"A, then B5 on the next line",
				],
				"answer": 0,
				"error_type": "LOGICAL",
				"output": "AB\n5",
			},

			
			{
				"type": "find_line",
				"topic": "Comments",
				"title": "Comments",
				"prompt": "Select every line the compiler ignores completely, then Submit.",
				"lines": [
					"// My first program",
					"public class Main {",
					"  public static void main(String[] args) {",
					"    System.out.println(\"Hi\"); // greet",
					"    /* System.out.println(\"Bye\"); */",
					"  }",
					"}",
				],
				"faulty": [1, 5],
				"multi": true,
				"error_type": "LOGICAL",
				"wrong_text": "this line still runs",
				"missed_text": "%d ignored line(s) still unmarked",
				"output": "Hi",
			},
		],
	},

	2: {
		"title": "Letters and Numbers",
		"steps": [
			{
				"type": "slots",
				"topic": "Variables, Print Variables, Multiple Variables",
				"title": "Variables",
				"file": "Main.java",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    <<t1:70>> name = \"ACE\";",
					"    int x = 5, <<v2:40>> = 6;",
					"    System.out.println(name);",
					"    System.out.println(x + y);",
					"  }",
					"}",
				],
				"answers": {
					"t1": "String",
					"v2": "y",
				},
				"accept": {
					"t1": ["var"],
				},
				"decoys": ["int", "z"],
				"typed_errors": {
					"t1": {
						"int": "incompatible types: \"ACE\" cannot be converted to int",
						"double": "incompatible types: \"ACE\" cannot be converted to double",
						"boolean": "incompatible types: \"ACE\" cannot be converted to boolean",
						"char": "incompatible types: \"ACE\" cannot be converted to char",
					},
					"v2": {
						"int": "<identifier> expected",
					},
				},
				"errors": {
					"v2": "cannot find symbol: the program uses a variable that was never declared",
				},
				"empty_errors": {
					"t1": {"type": "COMPILE", "text": "cannot find symbol: name was never declared"},
					"v2": {"type": "COMPILE", "text": "<identifier> expected"},
				},
				"error_lines": {
					"v2": 6,
				},
				"output": "ACE\n11",
			},

			{
				"type": "classify",
				"topic": "Identifiers",
				"title": "Identifiers",
				"prompt": "Which of these are legal Java variable names (identifiers)?",
				"choices": ["Valid", "Invalid"],
				"items": [
					{"text": "myVar", "answer": "Valid"},
					{"text": "2ndPlace", "answer": "Invalid"},
					{"text": "_score", "answer": "Valid"},
					{"text": "my-var", "answer": "Invalid"},
					{"text": "class", "answer": "Invalid"},
					{"text": "$price", "answer": "Valid"},
				],
				"error_type": "COMPILE",
				"error_text": "'%s' cannot be marked '%s'",
			},

			{
				"type": "classify",
				"topic": "Data Types",
				"title": "Data Types",
				"prompt": "Match each literal value to its data type.",
				"choices": ["int", "double", "char", "String", "boolean"],
				"items": [
					{"text": "42", "answer": "int"},
					{"text": "3.14", "answer": "double"},
					{"text": "'A'", "answer": "char"},
					{"text": "\"A\"", "answer": "String"},
					{"text": "true", "answer": "boolean"},
				],
				"error_type": "LOGICAL",
				"error_text": "the literal %s is not of type %s",
			},

			{
				"type": "slots",
				"topic": "Constants, the var keyword",
				"title": "var & final",
				"file": "Main.java",
				"hint": "Make MAX a constant that cannot change, and let Java work out the type of score.",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    <<kw_final:60>> int MAX = 10;",
					"    <<kw_var:50>> score = 5;",
					"    System.out.println(MAX + score);",
					"  }",
					"}",
				],
				"answers": {
					"kw_final": "final",
					"kw_var": "var",
				},
				"decoys": ["const", "int"],
				"wrong_but_valid": {
					"kw_var": ["int", "double", "long", "char"],
				},
				"valid_errors": {
					"kw_var": "that compiles, but it does not let Java work out the type ('%s')",
				},
				"errors": {
					"kw_final": "not a statement",
				},
				"typed_errors": {
					"kw_final": {
						"const": "illegal start of expression",
					},
					"kw_var": {
						"const": "illegal start of expression",
						"String": "incompatible types: int cannot be converted to String",
						"boolean": "incompatible types: int cannot be converted to boolean",
					},
				},
				"empty_errors": {
					"kw_final": {"type": "LOGICAL", "text": "MAX is not protected from changes"},
					"kw_var": {"type": "COMPILE", "text": "cannot find symbol: score was never declared"},
				},
				"output": "15",
			},

			{
				"type": "trace",
				"topic": "Arithmetic, Assignment",
				"title": "Arithmetic",
				"prompt": "Trace x. What is its value after each line runs?",
				"vars": ["x"],
				"first_line": 3,
				"rows": [
					{"code": "int x = 10;", "values": {"x": "10"}},
					{"code": "x = x + 5;", "values": {"x": "15"}},
					{"code": "x -= 3;", "values": {"x": "12"}},
					{"code": "x *= 2;", "values": {"x": "24"}},
					{"code": "x++;", "values": {"x": "25"}},
					{"code": "x = x % 7;", "values": {"x": "4"}},
				],
				"output": "x = 4",
			},

			{
				"type": "predict",
				"topic": "Comparison, Logical, Precedence",
				"title": "Precedence",
				"prompt": "Read the program, then pick what it prints.",
				"lines": [
					"int a = 5;",
					"int b = 10;",
					"System.out.println(a < b && b == 10);",
					"System.out.println(2 + 3 * 4);",
				],
				"question": "What does it print?",
				"options": ["true, then 14", "true, then 20", "false, then 14", "false, then 20"],
				"answer": 0,
				"error_type": "LOGICAL",
				"output": "true\n14",
			},
		],
	},

	3: {
		"title": "Strings, Math & Booleans",
		"steps": [
			{
				"type": "slots",
				"topic": "Strings",
				"title": "Strings",
				"file": "Main.java",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    String txt = \"Hello\";",
					"    System.out.println(txt.<<m1:90>>());",
					"    System.out.println(txt.<<m2:110>>());",
					"  }",
					"}",
				],
				"answers": {
					"m1": "length",
					"m2": "toUpperCase",
				},
				"decoys": ["size", "toLowerCase"],
				"wrong_but_valid": {
					"m1": ["toUpperCase", "toLowerCase", "trim"],
					"m2": ["toLowerCase", "length", "trim"],
				},
				"empty_errors": {
					"m1": {"type": "COMPILE", "text": "<identifier> expected"},
					"m2": {"type": "COMPILE", "text": "<identifier> expected"},
				},
				"output": "5\nHELLO",
			},

			{
				"type": "predict",
				"topic": "Concatenation, Numbers and Strings",
				"title": "Concatenation",
				"prompt": "Read the program, then pick what it prints.",
				"lines": [
					"System.out.println(\"10\" + 20);",
					"System.out.println(10 + 20 + \"x\");",
					"System.out.println(\"x\" + 10 + 20);",
				],
				"question": "What does it print on its 3 lines?",
				"options": [
					"1020, 30x, x1020",
					"30, 30x, x30",
					"1020, 30x, x30",
					"30, 30x, x1020",
				],
				"answer": 0,
				"error_type": "LOGICAL",
				"output": "1020\n30x\nx1020",
			},

			{
				"type": "find_line",
				"topic": "Special Characters",
				"title": "Special Chars",
				"prompt": "The compiler reports:\n  error: ')' or ',' expected\nClick the line it is complaining about, then Submit.",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    System.out.println(\"Say \\\"Hi\\\"\");",
					"    System.out.println(\"Hi \"Bob\" hi\");",
					"  }",
					"}",
				],
				"faulty": [4],
				"multi": false,
				"error_type": "COMPILE",
				"wrong_text": "no error found on this line",
				"output": "Say \"Hi\"\nHi \"Bob\" hi",
			},

			{
				"type": "predict",
				"topic": "Math, Booleans",
				"title": "Math & Booleans",
				"prompt": "Read the program, then pick what it prints.",
				"lines": [
					"System.out.println(Math.max(5, 10));",
					"System.out.println(Math.sqrt(64));",
					"System.out.println(10 > 9);",
				],
				"question": "What does it print on its 3 lines?",
				"options": [
					"10, 8.0, true",
					"5, 8, true",
					"10, 8, true",
					"10, 8.0, false",
				],
				"answer": 0,
				"error_type": "LOGICAL",
				"output": "10\n8.0\ntrue",
			},
		],
	},

	4: {
		"title": "Conditions",
		"steps": [
			
			{
				"type": "slots",
				"topic": "If, Else",
				"title": "If & Else",
				"file": "Main.java",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    int x = 20;",
					"    <<kw_if:40>> (x > 10) {",
					"      System.out.println(\"Big\");",
					"    } <<kw_else:50>> {",
					"      System.out.println(\"Small\");",
					"    }",
					"  }",
					"}",
				],
				"answers": {
					"kw_if": "if",
					"kw_else": "else",
				},
				"decoys": ["elif", "then", "else if"],
				"errors": {
					"kw_if": "';' expected",
					"kw_else": "not a statement",
				},
				"typed_errors": {
					"kw_if": {
						"else if": "'else' without 'if'",
					},
					"kw_else": {
						"else if": "'(' expected",
					},
				},
				"empty_errors": {
					"kw_if": {"type": "COMPILE", "text": "not a statement"},
					"kw_else": {"type": "LOGICAL", "text": "the second block runs every time"},
				},
				"output": "Big",
			},

			
			{
				"type": "predict",
				"topic": "Else If",
				"title": "Else If",
				"lines": [
					"int score = 75;",
					"if (score >= 90) {",
					"  System.out.println(\"A\");",
					"} else if (score >= 70) {",
					"  System.out.println(\"B\");",
					"} else {",
					"  System.out.println(\"C\");",
					"}",
				],
				"question": "What does it print?",
				"options": ["A", "B", "C", "B and C"],
				"answer": 1,
				"error_type": "LOGICAL",
				"output": "B",
			},

			{
				"type": "slots",
				"topic": "Short Hand If...Else",
				"title": "Short-hand If",
				"file": "Main.java",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    int age = 20;",
					"    String r = (age >= 18) <<q:30>> \"yes\" <<c:30>> \"no\";",
					"    System.out.println(r);",
					"  }",
					"}",
				],
				"answers": {
					"q": "?",
					"c": ":",
				},
				"decoys": ["=>", "->", ";"],
				"errors": {
					"q": "';' expected",
					"c": ": expected",
				},
				"typed_errors": {
					"q": {
						";": "not a statement",
						"=>": "illegal start of expression",
					},
					"c": {
						"=>": "illegal start of expression",
					},
				},
				"output": "yes",
			},

			{
				"type": "find_line",
				"topic": "Nested If",
				"title": "Nested If",
				"prompt": "The compiler reports:\n  error: incompatible types: int cannot be converted to boolean\nClick the line it is complaining about, then Submit.",
				"lines": [
					"int age = 20;",
					"if (age >= 18) {",
					"  if (age = 20) {",
					"    System.out.println(\"Twenty\");",
					"  }",
					"}",
				],
				"faulty": [3],
				"multi": false,
				"error_type": "COMPILE",
				"wrong_text": "no error found on this line",
				"output": "Twenty",
			},

			
			{
				"type": "predict",
				"topic": "Switch",
				"title": "Switch",
				"lines": [
					"int day = 2;",
					"switch (day) {",
					"  case 1: System.out.print(\"A\");",
					"  case 2: System.out.print(\"B\");",
					"  case 3: System.out.print(\"C\"); break;",
					"  default: System.out.print(\"D\");",
					"}",
				],
				"question": "What does it print?",
				"options": ["B", "BC", "BCD", "ABC"],
				"answer": 1,
				"error_type": "LOGICAL",
				"output": "BC",
			},
		],
	},

	5: {
		"title": "While Loops",
		"steps": [
			
			{
				"type": "slots",
				"topic": "While Loop",
				"title": "While Loop",
				"file": "Main.java",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    int i = 0;",
					"    while (<<cond:70>>) {",
					"      System.out.println(i);",
					"      <<inc:50>>;",
					"    }",
					"  }",
					"}",
				],
				"answers": {
					"cond": "i < 3",
					"inc": "i++",
				},
				"accept": {
					"cond": ["i <= 2", "3 > i", "2 >= i"],
					"inc": ["i += 1", "++i", "i = i + 1"],
				},
				"decoys": ["i > 3", "i < 4", "i--"],
				"wrong_but_valid": {
					"cond": ["i > 3", "i < 4", "i <= 3", "i < 2", "i <= 1"],
					"inc": ["i--", "i += 2", "i += 0"],
				},
				"valid_errors": {
					"cond": "the loop runs the wrong number of times",
					"inc": "the loop does not end after 3 passes",
				},
				"errors": {
					"inc": "not a statement",
				},
				"typed_errors": {
					"cond": {
						"i--": "incompatible types: int cannot be converted to boolean",
					},
					"inc": {
						"i < 4": "illegal start of type",
					},
				},
				"empty_errors": {
					"inc": {"type": "LOGICAL", "text": "the loop never ends: nothing changes i"},
				},
				"output": "0\n1\n2",
			},

			{
				"type": "trace",
				"topic": "While Loop",
				"title": "Trace a Loop",
				"prompt": "int i = 1, sum = 0;\nwhile (i <= 3) { sum += i; i++; }\nTrace i and sum after each pass.",
				"vars": ["i", "sum"],
				"rows": [
					{"code": "start", "values": {"i": "1", "sum": "0"}},
					{"code": "pass 1", "values": {"i": "2", "sum": "1"}},
					{"code": "pass 2", "values": {"i": "3", "sum": "3"}},
					{"code": "pass 3", "values": {"i": "4", "sum": "6"}},
				],
				"output": "sum = 6",
			},

			{
				"type": "find_line",
				"topic": "While Loop",
				"title": "Endless Loop",
				"prompt": "The program prints 0, -1, -2 ... and never stops.\nThe compiler reports nothing wrong.\nClick the line that keeps the loop alive.",
				"lines": [
					"int i = 0;",
					"while (i < 3) {",
					"  System.out.println(i);",
					"  i--;",
					"}",
				],
				"faulty": [4],
				"multi": false,
				"error_type": "LOGICAL",
				"wrong_text": "this line is not what keeps the loop running",
				"output": "0\n1\n2",
			},

			{
				"type": "predict",
				"topic": "Do/While Loop",
				"title": "Do/While",
				"lines": [
					"int i = 10;",
					"do {",
					"  System.out.println(\"ran\");",
					"  i++;",
					"} while (i < 5);",
				],
				"question": "How many times does \"ran\" print?",
				"options": ["0 times", "1 time", "5 times", "forever"],
				"answer": 1,
				"error_type": "LOGICAL",
				"output": "ran",
			},


			{
				"type": "order",
				"topic": "Do/While Loop",
				"title": "Assemble",
				"prompt": "Put the lines in order so the program prints 1, 2, 3.",
				"lines": [
					"int i = 1;",
					"do {",
					"  System.out.println(i);",
					"  i++;",
					"} while (i <= 3);",
				],
				"start_order": [2, 4, 0, 3, 1],
				"error_type": "LOGICAL",
				"wrong_text": "this line is not in the right place",
				"output": "1\n2\n3",
			},
		],
	},

	6: {
		"title": "For Loops",
		"steps": [
			{
				"type": "slots",
				"topic": "For Loop",
				"title": "For Loop",
				"file": "Main.java",
				"lines": [
					"public class Main {",
					"  public static void main(String[] args) {",
					"    <<kw_for:40>> (int i = 0; <<cond:60>>; <<inc:50>>) {",
					"      System.out.println(i);",
					"    }",
					"  }",
					"}",
				],
				"answers": {
					"kw_for": "for",
					"cond": "i < 3",
					"inc": "i++",
				},
				"accept": {
					"cond": ["i <= 2", "3 > i", "2 >= i"],
					"inc": ["i += 1", "++i", "i = i + 1"],
				},
				"decoys": ["while", "i < 4", "i--"],
				"wrong_but_valid": {
					"cond": ["i > 3", "i < 4", "i <= 3", "i < 2", "i <= 1"],
					"inc": ["i--", "i += 2", "i += 0"],
				},
				"valid_errors": {
					"cond": "the loop runs the wrong number of times",
					"inc": "the loop does not end after 3 passes",
				},
				"errors": {
					"kw_for": "'.class' expected",
					"inc": "not a statement",
				},
				"typed_errors": {
					"kw_for": {
						"i < 4": "illegal start of type",
						"i--": "';' expected",
					},
					"cond": {
						"i--": "incompatible types: int cannot be converted to boolean",
						"while": "illegal start of expression",
					},
					"inc": {
						"while": "illegal start of expression",
					},
				},
				"empty_errors": {
					"kw_for": {"type": "COMPILE", "text": "',', ')', or '[' expected"},
					"cond": {"type": "LOGICAL", "text": "the loop has no condition, so it never ends"},
					"inc": {"type": "LOGICAL", "text": "the loop never ends: nothing changes i"},
				},
				"output": "0\n1\n2",
			},

			{
				"type": "trace",
				"topic": "For Loop",
				"title": "Trace a Loop",
				"prompt": "int sum = 0;\nfor (int i = 1; i <= 4; i++) {\n  sum += i;\n}\nTrace i and sum at the end of each pass.",
				"vars": ["i", "sum"],
				"rows": [
					{"code": "pass 1", "values": {"i": "1", "sum": "1"}},
					{"code": "pass 2", "values": {"i": "2", "sum": "3"}},
					{"code": "pass 3", "values": {"i": "3", "sum": "6"}},
					{"code": "pass 4", "values": {"i": "4", "sum": "10"}},
				],
				"output": "sum = 10",
			},


			{
				"type": "predict",
				"topic": "For Loop",
				"title": "Off by One",
				"lines": [
					"for (int i = 1; i <= 3; i++) {",
					"  System.out.print(i + \" \");",
					"}",
				],
				"question": "What does it print?",
				"options": ["1 2", "1 2 3", "0 1 2 3", "1 2 3 4"],
				"answer": 1,
				"error_type": "LOGICAL",
				"output": "1 2 3",
			},

			{
				"type": "predict",
				"topic": "Nested Loops",
				"title": "Nested Count",
				"lines": [
					"int n = 0;",
					"for (int i = 0; i < 2; i++) {",
					"  for (int j = 0; j < 3; j++) {",
					"    n++;",
					"  }",
					"}",
					"System.out.println(n);",
				],
				"question": "What number does it print?",
				"answer": "6",
				"error_type": "LOGICAL",
				"output": "6",
			},

			{
				"type": "trace",
				"topic": "Nested Loops",
				"title": "Nested Trace",
				"prompt": "for (int i = 1; i <= 2; i++) {\n  for (int j = 1; j <= 2; j++) {\n    System.out.println(i + \",\" + j);\n  }\n}\nWhat are i and j on each print?",
				"vars": ["i", "j"],
				"rows": [
					{"code": "print 1", "values": {"i": "1", "j": "1"}},
					{"code": "print 2", "values": {"i": "1", "j": "2"}},
					{"code": "print 3", "values": {"i": "2", "j": "1"}},
					{"code": "print 4", "values": {"i": "2", "j": "2"}},
				],
				"output": "1,1\n1,2\n2,1\n2,2",
			},
		],
	},
}


const FINAL_PROGRAM := {
	"type": "slots",
	"title": "Trace(it)back",
	"file": "Main.java",
	"lines": [
		"public class Main {",
		"  public static void main(String[] args) {",
		"    // ACE boot log",
		"    System.out.<<s1_call:70>>(\"ACE online\")<<s1_semi:30>>",
		"    <<s2_final:60>> int MAX = 3;",
		"    <<s2_var:50>> lives = 3;",
		"    int score = lives <<s2_mul:30>> 2 + MAX;",
		"    <<s3_type:70>> name = \"ACE\";",
		"    System.out.println(name + \" \" + name.<<s3_len:80>>());",
		"    System.out.println(Math.<<s3_max:50>>(score, 10));",
		"    boolean ready = score <<s3_cmp:30>> 8;",
		"    <<s4_if:40>> (ready) {",
		"      System.out.println(\"READY\");",
		"    } <<s4_else:50>> {",
		"      System.out.println(\"WAIT\");",
		"    }",
		"    switch (lives) {",
		"      case 3: System.out.println(\"three\");",
		"        <<s4_break:60>>;",
		"      default: System.out.println(\"other\");",
		"    }",
		"    int i = 0;",
		"    while (<<s5_cond:60>>) {",
		"      System.out.println(i);",
		"      <<s5_inc:50>>;",
		"    }",
		"    for (int a = 1; <<s6_cond:60>>; a++) {",
		"      for (int b = 1; b <= 2; <<s6_inc:50>>) {",
		"        System.out.println(a + \",\" + b);",
		"      }",
		"    }",
		"  }",
		"}",
	],
	"sections": [
		0, 0,
		1, 1,
		2, 2, 2,
		3, 3, 3, 3,
		4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
		5, 5, 5, 5, 5,
		6, 6, 6, 6, 6,
		0, 0,
	],
	"answers": {
		"s1_call": "println",
		"s1_semi": ";",
		"s2_final": "final",
		"s2_var": "var",
		"s2_mul": "*",
		"s3_type": "String",
		"s3_len": "length",
		"s3_max": "max",
		"s3_cmp": ">",
		"s4_if": "if",
		"s4_else": "else",
		"s4_break": "break",
		"s5_cond": "i < 3",
		"s5_inc": "i++",
		"s6_cond": "a <= 2",
		"s6_inc": "b++",
	},
	"accept": {
		"s2_var": ["int"],
		"s3_type": ["var"],
		"s3_cmp": [">=", "!="],
		"s5_cond": ["i <= 2", "3 > i", "2 >= i"],
		"s5_inc": ["i += 1", "++i", "i = i + 1"],
		"s6_cond": ["a < 3", "2 >= a", "3 > a"],
		"s6_inc": ["b += 1", "++b", "b = b + 1"],
	},
	"decoys_by_section": {
		1: ["print"],
		2: ["const", "+", "-", "/"],
		3: ["int", "min", "size", "<", "=="],
		4: ["elif", "then", "continue"],
		5: ["i--", "i < 4", "i > 3"],
		6: ["a < 2", "b--", "a--"],
	},
	"wrong_but_valid": {
		"s1_call": ["print"],
		"s2_mul": ["+", "-", "/"],
		"s3_len": ["toUpperCase", "toLowerCase", "trim"],
		"s3_max": ["min"],
		"s3_cmp": ["<", "<=", "=="],
		"s5_cond": ["i < 4", "i <= 3", "i > 3", "i < 2"],
		"s5_inc": ["i--", "i += 2", "i += 0"],
		"s6_cond": ["a < 2", "a <= 1", "a <= 3", "a > 2"],
		"s6_inc": ["b--", "b += 2", "b += 0", "a--"],
	},
	"valid_errors": {
		"s1_call": "the next output continues on the same line",
		"s2_mul": "score gets the wrong value",
		"s3_len": "line 9 printed the wrong result",
		"s3_max": "line 10 printed the wrong result",
		"s3_cmp": "ready has the wrong value",
		"s5_cond": "the while loop runs the wrong number of times",
		"s5_inc": "the while loop does not end after 3 passes",
		"s6_cond": "the outer for loop runs the wrong number of times",
		"s6_inc": "the inner for loop does not end after 2 passes",
	},
	"errors": {
		"s1_semi": "';' expected",
		"s2_final": "not a statement",
		"s2_mul": "';' expected",
		"s3_cmp": "';' expected",
		"s4_if": "';' expected",
		"s4_else": "not a statement",
		"s4_break": "not a statement",
		"s5_inc": "not a statement",
		"s6_inc": "not a statement",
	},
	"typed_errors": {
		"s2_final": {
			"const": "illegal start of expression",
			"/": "illegal start of expression",
			"+": "'.class' expected",
			"-": "'.class' expected",
		},
		"s2_var": {
			"const": "illegal start of expression",
			"/": "illegal start of expression",
		},
		"s3_type": {
			"int": "incompatible types: \"ACE\" cannot be converted to int",
			"double": "incompatible types: \"ACE\" cannot be converted to double",
			"boolean": "incompatible types: \"ACE\" cannot be converted to boolean",
			"char": "incompatible types: \"ACE\" cannot be converted to char",
			"<": "> or ',' expected",
			"==": "illegal start of expression",
		},
		"s3_len": {
			"<": "illegal start of type",
			"==": "<identifier> expected",
			"int": "<identifier> expected",
		},
		"s3_max": {
			"<": "illegal start of type",
			"==": "<identifier> expected",
			"int": "<identifier> expected",
		},
		"s4_else": {
			"continue": "';' expected",
		},
		"s4_break": {
			"continue": "continue outside of loop",
		},
		"s5_cond": {
			"i--": "incompatible types: int cannot be converted to boolean",
		},
		"s5_inc": {
			"i < 4": "illegal start of type",
		},
		"s6_cond": {
			"a--": "incompatible types: int cannot be converted to boolean",
		},
	},
	"empty_errors": {
		"s1_call": {"type": "COMPILE", "text": "<identifier> expected"},
		"s2_final": {"type": "LOGICAL", "text": "MAX is not protected from changes"},
		"s2_var": {"type": "COMPILE", "text": "cannot find symbol: lives was never declared"},
		"s3_type": {"type": "COMPILE", "text": "cannot find symbol: name was never declared"},
		"s3_len": {"type": "COMPILE", "text": "<identifier> expected"},
		"s3_max": {"type": "COMPILE", "text": "<identifier> expected"},
		"s4_if": {"type": "COMPILE", "text": "not a statement"},
		"s4_else": {"type": "LOGICAL", "text": "the second block runs every time"},
		"s4_break": {"type": "LOGICAL", "text": "case 3 falls through into default"},
		"s5_inc": {"type": "LOGICAL", "text": "the while loop never ends: nothing changes i"},
		"s6_cond": {"type": "LOGICAL", "text": "the outer for loop has no condition, so it never ends"},
		"s6_inc": {"type": "LOGICAL", "text": "the inner for loop never ends: nothing changes b"},
	},
	"output": "ACE online\nACE 3\n10\nREADY\nthree\n0\n1\n2\n1,1\n1,2\n2,1\n2,2",
	"spec": [
		"Write Main.java:",
		"1  a comment, then print: ACE online",
		"2  constant MAX = 3, var lives = 3",
		"   score = lives * 2 + MAX",
		"3  String name = \"ACE\"",
		"   print name, a space, its length",
		"   print the bigger of score and 10",
		"   boolean ready: is score above 8?",
		"4  if ready print READY, else WAIT",
		"   switch lives: case 3 prints three",
		"   and stops; default prints other",
		"5  int i = 0; while i < 3: print i, i++",
		"6  for a = 1..2 { for b = 1..2 {",
		"   print a,b  (like 1,1) } }",
	],
}


const FINAL_HINTS := [
	{
		"id": "bedroom",
		"interaction": "BEDROOM_DRAWER",
		"room": "Bedroom",
		"section": 1,
		"title": "Boot log",
		"text": "System.out.println(\"ACE online\");",
	},
	{
		"id": "bathroom",
		"interaction": "BATHROOM_SINK",
		"room": "Bathroom",
		"section": 2,
		"title": "Score",
		"text": "int score = lives * 2 + MAX;",
	},
	{
		"id": "dining",
		"interaction": "ROOM2_DINING_TABLE",
		"room": "Dining room",
		"section": 3,
		"title": "Name tag",
		"text": "System.out.println(name + \" \" + name.length());",
	},
	{
		"id": "kitchen",
		"interaction": "ROOM3_FRIDGE",
		"room": "Kitchen",
		"section": 4,
		"title": "Switch",
		"text": "switch (lives) {\n  case 3: ...;\n    break;\n  default: ...;\n}",
	},
	{
		"id": "livingroom",
		"interaction": "ROOM4_TV",
		"room": "Living room",
		"section": 5,
		"title": "Countdown",
		"text": "while (i < 3) {\n  System.out.println(i);\n  i++;\n}",
	},
	{
		"id": "computer",
		"interaction": "COMPUTERROOM_BOOKSHELF",
		"room": "Computer room",
		"section": 6,
		"title": "Grid",
		"text": "for (int a = 1; a <= 2; a++) {\n  for (int b = 1; b <= 2; b++) {\n    ...\n  }\n}",
	},
]



const DATA_TYPES := ["int", "double", "boolean", "char", "String"]

const OPERATORS := ["=", "==", "!=", ">", "<", ">=", "<=", "+", "-", "*", "/", "%", "&&", "||", "!"]

const KEYWORDS := ["if", "else", "switch", "case", "break", "default", "while", "do", "for"]



static func has_puzzle(id: int) -> bool:
	return PUZZLES.has(id)


static func get_puzzle(id: int) -> Dictionary:
	return PUZZLES.get(id, {})


static func get_curriculum(id: int) -> Dictionary:
	return CURRICULUM.get(id, {})


static func puzzle_title(id: int) -> String:
	if id == 0:
		return "Intro Quiz"
	return str(get_curriculum(id).get("title", "Puzzle %d" % id))


static func get_steps(id: int) -> Array:
	return get_puzzle(id).get("steps", [])


static func step_count(id: int) -> int:
	return get_steps(id).size()



static func step_label(id: int, index: int) -> String:
	return "%d.%d" % [id, index + 1]


static func format_message(file_name: String, line: int, error_type: String, text: String) -> String:
	var label := "error"
	if error_type == "LOGICAL":
		label = "logical error"
	elif error_type == "RUNTIME":
		label = "runtime error"

	if line > 0:
		return "%s:%d: %s: %s" % [file_name, line, label, text]
	return "%s: %s" % [label, text]


static func hint_count() -> int:
	return FINAL_HINTS.size()


static func is_hint(hint_id: String) -> bool:
	for hint in FINAL_HINTS:
		if str(hint["id"]) == hint_id:
			return true
	return false


static func get_hint(hint_id: String) -> Dictionary:
	for hint in FINAL_HINTS:
		if str(hint["id"]) == hint_id:
			return hint
	return {}



static func hint_for_interaction(interaction_id: String) -> String:
	for hint in FINAL_HINTS:
		if str(hint["interaction"]) == interaction_id:
			return str(hint["id"])
	return ""



static func validate_final() -> Array:
	var problems: Array = validate_step("7", FINAL_PROGRAM)
	var lines: Array = FINAL_PROGRAM["lines"]
	var sections: Array = FINAL_PROGRAM["sections"]
	if sections.size() != lines.size():
		problems.append("7: sections has %d entries but there are %d lines" % [sections.size(), lines.size()])

	for i in range(lines.size()):
		for part in parse_line(str(lines[i])):
			if part.has("slot") and i < sections.size():
				if int(str(part["slot"]).substr(1, 1)) != int(sections[i]):
					problems.append("7: slot '%s' is on a line of section %d" % [part["slot"], sections[i]])

	var seen_sections := {}
	for hint in FINAL_HINTS:
		if seen_sections.has(hint["section"]):
			problems.append("7: two hints for section %d" % hint["section"])
		seen_sections[hint["section"]] = true
	return problems


static func get_answers(step: Dictionary) -> Dictionary:
	return step.get("answers", {})


static func accepted_answers(step: Dictionary, slot_id: String) -> Array:
	var accepted: Array = [str(get_answers(step).get(slot_id, ""))]
	for alternative in step.get("accept", {}).get(slot_id, []):
		accepted.append(str(alternative))
	return accepted

static func normalize_code(text: String) -> String:
	var result := ""
	var quote := ""
	var escaped := false
	var pending_space := false

	for i in range(text.length()):
		var c := text[i]

		if quote != "":
			result += c
			if escaped:
				escaped = false
			elif c == "\\":
				escaped = true
			elif c == quote:
				quote = ""
			continue

		if c == " " or c == "\t":
			pending_space = true
			continue

		if pending_space and result != "" and _is_word_char(result[result.length() - 1]) and _is_word_char(c):
			result += " "
		pending_space = false

		if c == "\"" or c == "'":
			quote = c
		result += c

	return result


static func _is_word_char(c: String) -> bool:
	return c == "_" or c == "$" or (c >= "0" and c <= "9") or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")

static func matches_answer(step: Dictionary, slot_id: String, got: String) -> bool:
	var normalized := normalize_code(got)
	for candidate in accepted_answers(step, slot_id):
		if normalize_code(str(candidate)) == normalized:
			return true
	return false

static func build_code_files(step: Dictionary) -> Array:
	var lines: Array = []
	for raw in step.get("lines", []):
		lines.append({"parts": parse_line(str(raw))})
	return [{"name": step.get("file", DEFAULT_FILE), "lines": lines}]

static func get_bank_words(step: Dictionary) -> Array:
	var words: Array = []
	var answers := get_answers(step)
	for slot_id in answers:
		var word := str(answers[slot_id])
		if not words.has(word):
			words.append(word)
	for decoy in step.get("decoys", []):
		var decoy_word := str(decoy)
		if not words.has(decoy_word):
			words.append(decoy_word)
	return words

static func parse_line(raw: String) -> Array:
	var parts: Array = []
	var rest := raw
	while true:
		var start := rest.find("<<")
		if start == -1:
			break
		var end := rest.find(">>", start + 2)
		if end == -1:
			break
		if start > 0:
			parts.append({"text": rest.substr(0, start)})
		var token := rest.substr(start + 2, end - start - 2)
		var pieces := token.split(":")
		var width := DEFAULT_SLOT_WIDTH
		if pieces.size() > 1:
			width = int(pieces[1])
		parts.append({"slot": pieces[0].strip_edges(), "width": width})
		rest = rest.substr(end + 2)
	if rest != "" or parts.is_empty():
		parts.append({"text": rest})
	return parts


static func get_slot_ids(step: Dictionary) -> Array:
	var ids: Array = []
	for raw in step.get("lines", []):
		for part in parse_line(str(raw)):
			if part.has("slot"):
				ids.append(part["slot"])
	return ids

static func get_slot_lines(step: Dictionary) -> Dictionary:
	var result := {}
	var line_number := 0
	for raw in step.get("lines", []):
		line_number += 1
		for part in parse_line(str(raw)):
			if part.has("slot"):
				result[part["slot"]] = line_number
	return result



static func _in_words(words: Array, got: String) -> bool:
	var normalized := normalize_code(got)
	for word in words:
		if normalize_code(str(word)) == normalized:
			return true
	return false



static func _typed_text(typed_errors: Dictionary, got: String):
	var normalized := normalize_code(got)
	for word in typed_errors:
		if normalize_code(str(word)) == normalized:
			return typed_errors[word]
	return null

static func describe_problem(step: Dictionary, slot_id: String, got: String) -> Dictionary:
	var file_name: String = step.get("file", DEFAULT_FILE)
	var line: int = int(step.get("error_lines", {}).get(slot_id, get_slot_lines(step).get(slot_id, 0)))
	var error_type: String = str(step.get("types", {}).get(slot_id, "COMPILE"))
	var custom = step.get("errors", {}).get(slot_id, null)

	if got == "" and step.get("empty_errors", {}).has(slot_id):
		var empty: Dictionary = step["empty_errors"][slot_id]
		error_type = str(empty.get("type", "COMPILE"))
		custom = str(empty.get("text", "incomplete code"))
	elif step.get("string_slots", []).has(slot_id):

		var quoted := got.length() >= 2 and got.begins_with("\"") and got.ends_with("\"")
		if quoted:
			error_type = "LOGICAL"
			custom = "the program printed the wrong text (%s)"
		else:
			error_type = "COMPILE"
			custom = step.get("unquoted_error", null)
			var typed_unquoted = _typed_text(step.get("typed_errors", {}).get(slot_id, {}), got)
			if typed_unquoted != null:
				custom = typed_unquoted
	elif _in_words(step.get("wrong_but_valid", {}).get(slot_id, []), got):
		error_type = "LOGICAL"
		custom = step.get("valid_errors", {}).get(slot_id, null)
	else:
		var typed = _typed_text(step.get("typed_errors", {}).get(slot_id, {}), got)
		if typed != null:
			error_type = "COMPILE"
			custom = typed

	var text: String
	if custom != null:
		text = str(custom)
		if text.contains("%s"):
			text = text.replace("%s", got)
	elif error_type == "LOGICAL":
		text = "line %d produced the wrong result" % line if got != "" else "line %d produced no result" % line
	elif error_type == "RUNTIME":
		text = "crashed on line %d" % line
	elif got == "":
		text = "illegal start of expression"
	else:
		text = "cannot find symbol  symbol: %s" % got

	return {
		"error_type": error_type,
		"message": format_message(file_name, line, error_type, text),
		"line": line,
		"file": file_name,
	}

static func validate(id: int) -> Array:
	var problems: Array = []
	var steps := get_steps(id)
	if steps.is_empty():
		problems.append("puzzle %d has no steps" % id)
		return problems

	for index in range(steps.size()):
		problems.append_array(validate_step(step_label(id, index), steps[index]))
	return problems


static func validate_step(label: String, step: Dictionary) -> Array:
	var step_type := str(step.get("type", "slots"))
	match step_type:
		"slots":
			return _validate_slots(label, step)
		"find_line":
			return _validate_find_line(label, step)
		"order":
			return _validate_order(label, step)
		"predict":
			return _validate_predict(label, step)
		"classify":
			return _validate_classify(label, step)
		"trace":
			return _validate_trace(label, step)
	return ["%s: unknown challenge type '%s'" % [label, step_type]]


static func _validate_slots(label: String, step: Dictionary) -> Array:
	var problems: Array = []
	var slot_ids := get_slot_ids(step)
	var answers := get_answers(step)

	if slot_ids.is_empty():
		problems.append("%s has no slots" % label)

	var seen := {}
	for slot_id in slot_ids:
		if seen.has(slot_id):
			problems.append("%s: slot '%s' is used twice" % [label, slot_id])
		seen[slot_id] = true
		if not answers.has(slot_id):
			problems.append("%s: slot '%s' has no answer" % [label, slot_id])

	for slot_id in answers:
		if not slot_ids.has(slot_id):
			problems.append("%s: answer '%s' has no slot" % [label, slot_id])

	for table_name in ["types", "errors", "accept", "empty_errors", "wrong_but_valid", "valid_errors", "typed_errors", "error_lines"]:
		for slot_id in step.get(table_name, {}):
			if not slot_ids.has(slot_id):
				problems.append("%s: '%s' mentions unknown slot '%s'" % [label, table_name, slot_id])
	for slot_id in step.get("string_slots", []):
		if not slot_ids.has(slot_id):
			problems.append("%s: string_slots mentions unknown slot '%s'" % [label, slot_id])

	for slot_id in step.get("types", {}):
		if not ERROR_TYPES.has(str(step["types"][slot_id])):
			problems.append("%s: unknown error type '%s'" % [label, step["types"][slot_id]])
	for slot_id in step.get("empty_errors", {}):
		if not ERROR_TYPES.has(str(step["empty_errors"][slot_id].get("type", "COMPILE"))):
			problems.append("%s: empty_errors for '%s' has an unknown type" % [label, slot_id])

	var texts: Array = []
	for slot_id in step.get("errors", {}):
		texts.append([slot_id, str(step["errors"][slot_id])])
	for slot_id in step.get("empty_errors", {}):
		texts.append([slot_id, str(step["empty_errors"][slot_id].get("text", ""))])
	for slot_id in step.get("valid_errors", {}):
		texts.append([slot_id, str(step["valid_errors"][slot_id])])
	for slot_id in step.get("typed_errors", {}):
		for word in step["typed_errors"][slot_id]:
			texts.append([slot_id, str(step["typed_errors"][slot_id][word])])
	for pair in texts:
		var answer := str(answers.get(pair[0], ""))
		if answer.length() > 2 and str(pair[1]).contains(answer):
			problems.append("%s: a message for '%s' may reveal the answer" % [label, pair[0]])

	for slot_id in step.get("wrong_but_valid", {}):
		for word in step["wrong_but_valid"][slot_id]:
			if matches_answer(step, str(slot_id), str(word)):
				problems.append("%s: '%s' is listed as wrong but is also correct for '%s'" % [label, word, slot_id])

	return problems


static func _validate_find_line(label: String, step: Dictionary) -> Array:
	var problems: Array = []
	var lines: Array = step.get("lines", [])
	var faulty: Array = step.get("faulty", [])

	if lines.is_empty():
		problems.append("%s has no lines" % label)
	if faulty.is_empty():
		problems.append("%s has no faulty line" % label)
	if not bool(step.get("multi", false)) and faulty.size() > 1:
		problems.append("%s: several faulty lines but multi is false" % label)
	for line_number in faulty:
		if int(line_number) < 1 or int(line_number) > lines.size():
			problems.append("%s: faulty line %s is out of range" % [label, line_number])
	return problems


static func _validate_order(label: String, step: Dictionary) -> Array:
	var problems: Array = []
	var lines: Array = step.get("lines", [])
	if lines.size() < 2:
		problems.append("%s needs at least 2 lines to order" % label)

	var start_order: Array = step.get("start_order", [])
	if not start_order.is_empty():
		var sorted_copy := start_order.duplicate()
		sorted_copy.sort()
		var expected: Array = []
		for i in range(lines.size()):
			expected.append(i)
		if sorted_copy != expected:
			problems.append("%s: start_order is not a permutation of the lines" % label)
		elif start_order == expected:
			problems.append("%s: start_order is already solved" % label)
	return problems


static func _validate_predict(label: String, step: Dictionary) -> Array:
	var problems: Array = []
	if step.get("lines", []).is_empty():
		problems.append("%s has no code to read" % label)

	if step.has("options"):
		var options: Array = step["options"]
		var answer := int(step.get("answer", -1))
		if options.size() < 2:
			problems.append("%s needs at least 2 options" % label)
		if options.size() > 4:
			problems.append("%s has more than 4 options" % label)
		if answer < 0 or answer >= options.size():
			problems.append("%s: answer index is out of range" % label)
	elif not step.has("answer"):
		problems.append("%s has no answer" % label)
	return problems


static func _validate_classify(label: String, step: Dictionary) -> Array:
	var problems: Array = []
	var choices: Array = step.get("choices", [])
	var items: Array = step.get("items", [])
	if choices.size() < 2:
		problems.append("%s needs at least 2 choices" % label)
	if items.is_empty():
		problems.append("%s has no items" % label)
	for item in items:
		if not choices.has(item.get("answer", null)):
			problems.append("%s: item '%s' has an answer that is not a choice" % [label, item.get("text", "?")])
	return problems


static func _validate_trace(label: String, step: Dictionary) -> Array:
	var problems: Array = []
	var trace_vars: Array = step.get("vars", [])
	var rows: Array = step.get("rows", [])
	if trace_vars.is_empty():
		problems.append("%s has no variables to trace" % label)
	if rows.is_empty():
		problems.append("%s has no rows" % label)
	for row_index in range(rows.size()):
		for variable in trace_vars:
			if not rows[row_index].get("values", {}).has(variable):
				problems.append("%s: row %d has no value for '%s'" % [label, row_index + 1, variable])
	return problems
