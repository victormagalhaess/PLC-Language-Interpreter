%%

%name PlcParser

%pos int

%term VAR | FUN | END | FN
    | IF | THEN | ELSE
    | MATCH | WITH
    | NEGATION | AND
    | HEAD | TAIL | ISEMPTY
    | PRINT
    | PLUS | MINUS | MULTI | DIV | NEGATIVE
    | EQ | DIF | SMALLER | SMALLEREQ 
    | DOUBLEPTS | COLON | SEMIC | COMMA | ARROW | VERTBAR | UNDERSCORE | FUNARROW
    | NIL | BOOL | INT
    | TRUE | FALSE
    | LPAR | RPAR | RKEY | LKEY | RBRACK | LBRACK
    | NAME of string | CINT of int | FUN of expr | LIST of list
    | EOF

%nonterm Prog of expr |
    | Decl of expr
    | Expr of expr
    | AtomExpr of expr
    | AppExpr of expr
    | Const of expr
    | Comps of expr list
    | MatchExpr of (expr option * expr) list 
    | CondExpr of expr option
    | Args of (plcType * string) list
    | Params of (plcType * string) list
    | TypedVar of plcType * string
    | Type of plcType
    | AtomType of plcType
    | Types of plcType list

%eop EOF

%right SEMIC DOUBLEPTS ARROW
%left ELSE AND EQ DIF SMALLER SMALLEREQ PLUS MINUS MULTI DIV LBRACK
%nonassoc IF NEGATION HEAD TAIL ISEMPTY PRINT NAME


%noshift EOF

%start Prog

%%

Prog : Expr (Expr) 
    | Decl (Decl)

Decl : VAR NAME EQ Expr SEMIC Prog (Let(NAME, Expr, Prog))
    | FUN NAME Args EQ Expr SEMIC Prog (Let(NAME, makeAnon(Args, Expr), Prog))
    | FUN REC NAME Args COLON Type EQ Expr SEMIC Prog (MakeFun(NAME, Args, Type, Expr, Prog))

Expr : AtomExpr(AtomExpr)
    | AppExpr(AppExpr)
    | IF Expr THEN Expr ELSE Expr (If(Expr1, Expr2, Expr3))
    | MATCH Expr WITH MatchExpr (Match (Expr, MatchExpr))
    | NEGATION Expr (Prim1("!", Expr))
    | Expr AND Expr (Prim2("&&", Expr1, Expr2))
    | HEAD Expr (Prim1("hd", Expr))
    | TAIL Expr (Prim1("tl", Expr))
    | ISEMPTY Expr (Prim1("ise"), Expr)
    | PRINT Expr (Prim1("print"), Expr)
    | Expr PLUS Expr (Prim2("+", Expr1, Expr2))
    | Expr MINUS Expr (Prim2("-", Expr1, Expr2))
    | Expr MULTI Expr (Prim2("*", Expr1, Expr2))
    | Expr DIV Expr (Prim2("/", Expr1, Expr2))
    | NEGATIVE Expr (Prim1("-", Expr))
    | Expr EQ Expr (Prim2("=", Expr1, Expr2))
    | Expr DIF Expr (Prim2("!=", Expr1, Expr2))
    | Expr SMALLER Expr (Prim2("<", Expr1, Expr2))
    | Expr SMALLEREQ Expr (Prim2("<=", Expr1, Expr2))
    | Expr DOUBLEPTS Expr (Prim2("::", Expr1, Expr2))
    | Expr LBRACK CINT RBRACK (Item (CINT, Expr))

AtomExpr: Const (Const)
    | NAME (Var(NAME))
    | LKEY Prog RKEY (Prog)
    | LPAR Comps RPAR (List Comps)
    | LPAR Expr RPAR (Expr)
    | FN Args FUNARROW Expr END (makeAnon(Args, Expr))

AppExpr: AtomExpr AtomExpr (Call(AtomExpr1, AtomExpr2))
    | AppExpr AtomExpr (Call(AppExpr, AtomExpr))

Const : TRUE (ConB(TRUE)) | FALSE (ConB(FALSE))
    | CINT ConI (CINT)
    | LPAR RPAR (Nil)
    | LPAR Type LBRACK RBRACK RPAR (ESeq(Type))

Comps: Expr COMMA Expr (Expr1 :: Expr2 :: [])
    | Expr COMMA Comps (Expr :: Comps)

MatchExpr : END (Nil)
    | VERTBAR CondExpr ARROW Expr MatchExpr ((CondExpr, Expr) :: MatchExpr)

CondExpr : Expr (SOME Expr)
    | UNDERSCORE (NONE)

Args : LPAR RPAR ([])
    | TypedVar COMMA Params (TypedVar :: Params)

TypedVar : Type NAME ((Type, NAME))

Type: AtomType(AtomType)
    | LPAR Types RPAR (ListT [])
    | LBRACK Type RBRACK (SeqT Type)
    | Type ARROW Type (FunT (Type1, Type2))

AtomType: NIL (ListT [])
    | BOOL (BoolT)
    | INT (IntT)
    | LPAR Type RPAR (Type)

Types : Type COMMA Type (Type1 :: Type2 :: [])
    | Type COMMA Types (Type :: Types)