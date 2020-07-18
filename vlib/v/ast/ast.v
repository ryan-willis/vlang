// Copyright (c) 2019-2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ast

import v.token
import v.table
import v.errors

pub type TypeDecl = AliasTypeDecl | FnTypeDecl | SumTypeDecl

pub type Expr = AnonFn | ArrayInit | AsCast | Assoc | BoolLiteral | CallExpr | CastExpr |
	CharLiteral | Comment | ComptimeCall | ConcatExpr | EnumVal | FloatLiteral | Ident | IfExpr |
	IfGuardExpr | IndexExpr | InfixExpr | IntegerLiteral | Likely | LockExpr | MapInit | MatchExpr |
	None | OrExpr | ParExpr | PostfixExpr | PrefixExpr | RangeExpr | SelectorExpr | SizeOf |
	SqlExpr | StringInterLiteral | StringLiteral | StructInit | Type | TypeOf | UnsafeExpr

pub type Stmt = AssertStmt | AssignStmt | Attr | Block | BranchStmt | CompFor | CompIf |
	ConstDecl | DeferStmt | EnumDecl | ExprStmt | FnDecl | ForCStmt | ForInStmt | ForStmt |
	GlobalDecl | GoStmt | GotoLabel | GotoStmt | HashStmt | Import | InterfaceDecl | Module |
	Return | SqlStmt | StructDecl | TypeDecl | UnsafeStmt

pub type ScopeObject = ConstField | GlobalDecl | Var

// pub type Type = StructType | ArrayType
// pub struct StructType {
// fields []Field
// }
// pub struct ArrayType {}
pub struct Type {
pub:
	typ table.Type
	pos token.Position
}

pub struct Block {
pub:
	stmts []Stmt
}

// | IncDecStmt k
// Stand-alone expression in a statement list.
pub struct ExprStmt {
pub:
	expr     Expr
	pos      token.Position
	comments []Comment
	is_expr  bool
pub mut:
	typ      table.Type
}

pub struct IntegerLiteral {
pub:
	val string
	pos token.Position
}

pub struct FloatLiteral {
pub:
	val string
	pos token.Position
}

pub struct StringLiteral {
pub:
	val      string
	is_raw   bool
	language table.Language
	pos      token.Position
}

// 'name: $name'
pub struct StringInterLiteral {
pub:
	vals       []string
	exprs      []Expr
	fwidths    []int
	precisions []int
	pluss      []bool
	fills      []bool
	fmt_poss   []token.Position
	pos        token.Position
pub mut:
	expr_types []table.Type
	fmts       []byte
	need_fmts  []bool // an explicit non-default fmt required, e.g. `x`
}

pub struct CharLiteral {
pub:
	val string
	pos token.Position
}

pub struct BoolLiteral {
pub:
	val bool
	pos token.Position
}

// `foo.bar`
pub struct SelectorExpr {
pub:
	pos        token.Position
	expr       Expr
	field_name string
pub mut:
	expr_type  table.Type // type of `Foo` in `Foo.bar`
	typ        table.Type // type of the entire thing (`Foo.bar`)
}

// module declaration
pub struct Module {
pub:
	name       string
	path       string
	expr       Expr
	pos        token.Position
	is_skipped bool // module main can be skipped in single file programs
}

pub struct StructField {
pub:
	name             string
	pos              token.Position
	comments         []Comment
	default_expr     Expr
	has_default_expr bool
	attrs            []string
	is_public        bool
pub mut:
	typ              table.Type
}

pub struct Field {
pub:
	name string
	pos  token.Position
pub mut:
	typ  table.Type
}

pub struct ConstField {
pub:
	mod      string
	name     string
	expr     Expr
	is_pub   bool
	pos      token.Position
pub mut:
	typ      table.Type
	comments []Comment
}

pub struct ConstDecl {
pub:
	is_pub bool
	pos    token.Position
pub mut:
	fields []ConstField
}

pub struct StructDecl {
pub:
	pos          token.Position
	name         string
	fields       []StructField
	is_pub       bool
	mut_pos      int // mut:
	pub_pos      int // pub:
	pub_mut_pos  int // pub mut:
	language     table.Language
	is_union     bool
	attrs        []string
	end_comments []Comment
}

pub struct InterfaceDecl {
pub:
	name        string
	field_names []string
	is_pub      bool
	methods     []FnDecl
	pos         token.Position
}

pub struct StructInitField {
pub:
	expr          Expr
	pos           token.Position
	comment       Comment
pub mut:
	name          string
	typ           table.Type
	expected_type table.Type
}

pub struct StructInit {
pub:
	pos      token.Position
	is_short bool
pub mut:
	typ      table.Type
	fields   []StructInitField
}

// import statement
pub struct Import {
pub:
	pos    token.Position
	mod    string
	alias  string
	is_sub bool = false
pub mut:
	subs   []ImportSub
}

// child import { submod1, submod2 }
pub struct ImportSub {
pub:
	pos    token.Position
	mod    string
	alias  string
	is_sub bool = true
}

pub type ImportModule = Import | ImportSub

pub fn (mi ImportModule) mod() string {
	match mi as i {
		Import    { return i.mod }
		ImportSub { return i.mod }
	}
}

pub fn (mi ImportModule) alias() string {
	match mi as i {
		Import    { return i.alias }
		ImportSub { return i.alias }
	}
}

pub struct AnonFn {
pub:
	decl FnDecl
pub mut:
	typ  table.Type
}

pub struct FnDecl {
pub:
	name          string
	mod           string
	args          []table.Arg
	is_deprecated bool
	is_pub        bool
	is_variadic   bool
	is_anon       bool
	receiver      Field
	receiver_pos  token.Position
	is_method     bool
	rec_mut       bool // is receiver mutable
	rec_share     table.ShareType
	language      table.Language
	no_body       bool // just a definition `fn C.malloc()`
	is_builtin    bool // this function is defined in builtin/strconv
	ctdefine      string // has [if myflag] tag
	pos           token.Position
	body_pos      token.Position
	file          string
	is_generic    bool
pub mut:
	stmts         []Stmt
	return_type   table.Type
}

pub struct BranchStmt {
pub:
	tok token.Token
}

pub struct CallExpr {
pub:
	pos                token.Position
	left               Expr // `user` in `user.register()`
	mod                string
pub mut:
	name               string
	is_method          bool
	is_field           bool // temp hack, remove ASAP when re-impl CallExpr / Selector (joe)
	args               []CallArg
	expected_arg_types []table.Type
	language           table.Language
	or_block           OrExpr
	left_type          table.Type // type of `user`
	receiver_type      table.Type // User
	return_type        table.Type
	should_be_skipped  bool
	generic_type       table.Type // TODO array, to support multiple types
}

pub struct CallArg {
pub:
	is_mut bool
	share  table.ShareType
	expr   Expr
pub mut:
	typ    table.Type
}

pub struct Return {
pub:
	pos      token.Position
	exprs    []Expr
	comments []Comment
pub mut:
	types    []table.Type
}

/*
pub enum Expr {
	Binary(InfixExpr)
	If(IfExpr)
	Integer(IntegerExpr)
}
*/
/*
pub struct Stmt {
	pos int
	//end int
}
*/
pub struct Var {
pub:
	name       string
	expr       Expr
	share      table.ShareType
	is_mut     bool
	is_arg     bool // fn args should not be autofreed
pub mut:
	typ        table.Type
	pos        token.Position
	is_used    bool
	is_changed bool // to detect mutable vars that are never changed
}

pub struct GlobalDecl {
pub:
	name     string
	expr     Expr
	has_expr bool
	pos      token.Position
pub mut:
	typ      table.Type
}

pub struct File {
pub:
	path         string
	mod          Module
	scope        &Scope
	global_scope &Scope
pub mut:
	stmts        []Stmt
	imports      []Import
	errors       []errors.Error
	warnings     []errors.Warning
}

pub struct IdentFn {
pub mut:
	typ table.Type
}

pub struct IdentVar {
pub mut:
	typ         table.Type
	is_mut      bool
	is_static   bool
	is_optional bool
	share       table.ShareType
}

pub type IdentInfo = IdentFn | IdentVar

pub enum IdentKind {
	unresolved
	blank_ident
	variable
	constant
	global
	function
}

// A single identifier
pub struct Ident {
pub:
	language table.Language
	tok_kind token.Kind
	pos      token.Position
pub mut:
	mod      string
	name     string
	kind     IdentKind
	info     IdentInfo
	is_mut   bool
}

pub fn (i &Ident) var_info() IdentVar {
	match i.info as info {
		IdentVar {
			return info
		}
		else {
			// return IdentVar{}
			panic('Ident.var_info(): info is not IdentVar variant')
		}
	}
}

pub struct InfixExpr {
pub:
	op          token.Kind
	pos         token.Position
	left        Expr
	right       Expr
pub mut:
	left_type   table.Type
	right_type  table.Type
	auto_locked string
}

pub struct PostfixExpr {
pub:
	op          token.Kind
	expr        Expr
	pos         token.Position
pub mut:
	auto_locked string
}

pub struct PrefixExpr {
pub:
	op    token.Kind
	right Expr
	pos   token.Position
}

pub struct IndexExpr {
pub:
	pos       token.Position
	left      Expr
	index     Expr // [0], [start..end] etc
pub mut:
	left_type table.Type // array, map, fixed array
	is_setter bool
}

pub struct IfExpr {
pub:
	tok_kind token.Kind
	left     Expr // `a` in `a := if ...`
	pos      token.Position
pub mut:
	branches []IfBranch // includes all `else if` branches
	is_expr  bool
	typ      table.Type
	has_else bool
}

pub struct IfBranch {
pub:
	cond         Expr
	stmts        []Stmt
	pos          token.Position
	body_pos     token.Position
	comments     []Comment
pub mut:
	smartcast    bool // should only be true if cond is `x is sumtype`, it will be set in checker - if_expr
	left_as_name string // only used in x is SumType check
}

pub struct UnsafeExpr {
pub:
	stmts []Stmt
	pos   token.Position
}

pub struct LockExpr {
pub:
	stmts    []Stmt
	is_rlock bool
	pos      token.Position
pub mut:
	lockeds  []Ident // `x`, `y` in `lock x, y {`
	is_expr  bool
	typ      table.Type
}

pub struct MatchExpr {
pub:
	tok_kind      token.Kind
	cond          Expr
	branches      []MatchBranch
	pos           token.Position
	is_mut        bool // `match mut ast_node {`
	var_name      string
pub mut:
	is_expr       bool // returns a value
	return_type   table.Type
	cond_type     table.Type // type of `x` in `match x {`
	expected_type table.Type // for debugging only
	is_sum_type   bool
	is_interface  bool
}

pub struct MatchBranch {
pub:
	exprs         []Expr // left side
	stmts         []Stmt // right side
	pos           token.Position
	comment       Comment // comment above `xxx {`
	is_else       bool
	post_comments []Comment
}

/*
CompIf.is_opt:
`$if xyz? {}` => this compile time `if` is optional,
and .is_opt reflects the presence of ? at the end.
When .is_opt is true, the code should compile, even
if `xyz` is NOT defined.
If .is_opt is false, then when `xyz` is not defined,
the compilation will fail.
*/
pub struct CompIf {
pub:
	val        string
	stmts      []Stmt
	is_not     bool
	pos        token.Position
pub mut:
	is_opt     bool
	has_else   bool
	else_stmts []Stmt
}

pub struct CompFor {
pub:
	val_var string
	stmts   []Stmt
pub mut:
	// expr    Expr
	typ     table.Type
}

pub struct ForStmt {
pub:
	cond   Expr
	stmts  []Stmt
	is_inf bool // `for {}`
	pos    token.Position
}

pub struct ForInStmt {
pub:
	key_var   string
	val_var   string
	cond      Expr
	is_range  bool
	high      Expr // `10` in `for i in 0..10 {`
	stmts     []Stmt
	pos       token.Position
pub mut:
	key_type  table.Type
	val_type  table.Type
	cond_type table.Type
	kind      table.Kind // array/map/string
}

pub struct ForCStmt {
pub:
	init     Stmt // i := 0;
	has_init bool
	cond     Expr // i < 10;
	has_cond bool
	inc      Stmt // i++; i += 2
	has_inc  bool
	stmts    []Stmt
	pos      token.Position
}

// #include etc
pub struct HashStmt {
pub:
	val string
	mod string
}

// filter(), map()
pub struct Lambda {
pub:
	name string
}

pub struct AssignStmt {
pub:
	right         []Expr
	op            token.Kind
	pos           token.Position
	comments      []Comment
pub mut:
	left          []Expr
	left_types    []table.Type
	right_types   []table.Type
	is_static     bool // for translated code only
	is_simple     bool // `x+=2` in `for x:=1; ; x+=2`
	has_cross_var bool
}

pub struct AsCast {
pub:
	expr      Expr
	typ       table.Type
	pos       token.Position
pub mut:
	expr_type table.Type
}

// e.g. `[unsafe_fn]`
pub struct Attr {
pub:
	name      string
	is_string bool // `['xxx']`
}

pub fn (attrs []Attr) contains(attr Attr) bool {
	for a in attrs {
		if attr.name == a.name {
			return true
		}
	}
	return false
}

pub struct EnumVal {
pub:
	enum_name string
	val       string
	mod       string // for full path `mod_Enum_val`
	pos       token.Position
pub mut:
	typ       table.Type
}

pub struct EnumField {
pub:
	name     string
	pos      token.Position
	comments []Comment
	expr     Expr
	has_expr bool
}

pub struct EnumDecl {
pub:
	name             string
	is_pub           bool
	is_flag          bool // true when the enum has [flag] tag
	is_multi_allowed bool
	comments         []Comment // enum Abc { /* comments */ ... }
	fields           []EnumField
	pos              token.Position
}

pub struct AliasTypeDecl {
pub:
	name        string
	is_pub      bool
	parent_type table.Type
	pos         token.Position
}

pub struct SumTypeDecl {
pub:
	name      string
	is_pub    bool
	sub_types []table.Type
	pos       token.Position
}

pub struct FnTypeDecl {
pub:
	name   string
	is_pub bool
	typ    table.Type
	pos    token.Position
}

// TODO: handle this differently
// v1 excludes non current os ifdefs so
// the defer's never get added in the first place
pub struct DeferStmt {
pub:
	stmts []Stmt
pub mut:
	ifdef string
}

pub struct UnsafeStmt {
pub:
	stmts []Stmt
}

// `(3+4)`
pub struct ParExpr {
pub:
	expr Expr
}

pub struct GoStmt {
pub:
	call_expr Expr
}

pub struct GotoLabel {
pub:
	name string
}

pub struct GotoStmt {
pub:
	name string
}

pub struct ArrayInit {
pub:
	pos             token.Position
	elem_type_pos   token.Position
	exprs           []Expr
	is_fixed        bool
	has_val         bool
	mod             string
	len_expr        Expr
	cap_expr        Expr
	default_expr    Expr
	has_len         bool
	has_cap         bool
	has_default     bool
pub mut:
	is_interface    bool // array of interfaces e.g. `[]Animal` `[Dog{}, Cat{}]`
	interface_types []table.Type // [Dog, Cat]
	interface_type  table.Type // Animal
	elem_type       table.Type
	typ             table.Type
}

pub struct MapInit {
pub:
	pos        token.Position
	keys       []Expr
	vals       []Expr
pub mut:
	typ        table.Type
	key_type   table.Type
	value_type table.Type
}

// s[10..20]
pub struct RangeExpr {
pub:
	low      Expr
	high     Expr
	has_high bool
	has_low  bool
}

pub struct CastExpr {
pub:
	expr      Expr // `buf`
	arg       Expr // `n` in `string(buf, n)`
	typ       table.Type // `string` TODO rename to `type_to_cast_to`
	pos       token.Position
pub mut:
	typname   string
	expr_type table.Type // `byteptr`
	has_arg   bool
}

pub struct AssertStmt {
pub:
	expr Expr
	pos  token.Position
}

// `if [x := opt()] {`
pub struct IfGuardExpr {
pub:
	var_name  string
	expr      Expr
pub mut:
	expr_type table.Type
}

pub enum OrKind {
	absent
	block
	propagate
}

// `or { ... }`
pub struct OrExpr {
pub:
	stmts []Stmt
	kind  OrKind
	pos   token.Position
}

pub struct Assoc {
pub:
	var_name string
	fields   []string
	exprs    []Expr
	pos      token.Position
pub mut:
	typ      table.Type
}

pub struct SizeOf {
pub:
	is_type   bool
	typ       table.Type
	type_name string
	expr      Expr
	pos       token.Position
}

pub struct Likely {
pub:
	expr      Expr
	pos       token.Position
	is_likely bool // false for _unlikely_
}

pub struct TypeOf {
pub:
	expr      Expr
pub mut:
	expr_type table.Type
}

pub struct Comment {
pub:
	text     string
	is_multi bool
	line_nr  int
	pos      token.Position
}

pub struct ConcatExpr {
pub:
	vals        []Expr
pub mut:
	return_type table.Type
}

pub struct ComptimeCall {
pub:
	method_name string
	left        Expr
	is_vweb     bool
	vweb_tmpl   File
	args_var    string
pub mut:
	sym         table.TypeSymbol
}

pub struct None {
pub:
	pos token.Position
	foo int // todo
}

/*
pub enum SqlExprKind {
	select_
	insert
	update
}
*/
pub enum SqlStmtKind {
	insert
	update
	delete
}

pub struct SqlStmt {
pub:
	kind            SqlStmtKind
	db_expr         Expr // `db` in `sql db {`
	object_var_name string // `user`
	table_type      table.Type
	pos             token.Position
	where_expr      Expr
	updated_columns []string // for `update set x=y`
	update_exprs    []Expr // for `update`
pub mut:
	table_name      string
	fields          []table.Field
}

pub struct SqlExpr {
pub:
	typ         table.Type
	is_count    bool
	db_expr     Expr // `db` in `sql db {`
	where_expr  Expr
	has_where   bool
	has_offset  bool
	offset_expr Expr
	has_order   bool
	order_expr  Expr
	has_desc    bool
	is_array    bool
	table_type  table.Type
	pos         token.Position
	has_limit   bool
	limit_expr  Expr
pub mut:
	table_name  string
	fields      []table.Field
}

[inline]
pub fn (expr Expr) is_blank_ident() bool {
	match expr {
		Ident { return expr.kind == .blank_ident }
		else { return false }
	}
}

pub fn (expr Expr) position() token.Position {
	// all uncommented have to be implemented
	match mut expr {
		AnonFn {
			return expr.decl.pos
		}
		ArrayInit {
			return expr.pos
		}
		AsCast {
			return expr.pos
		}
		Assoc {
			return expr.pos
		}
		BoolLiteral {
			return expr.pos
		}
		// ast.Ident { }
		CallExpr {
			return expr.pos
		}
		CastExpr {
			return expr.pos
		}
		CharLiteral {
			return expr.pos
		}
		Comment {
			return expr.pos
		}
		EnumVal {
			return expr.pos
		}
		FloatLiteral {
			return expr.pos
		}
		Ident {
			return expr.pos
		}
		IfExpr {
			return expr.pos
		}
		// ast.IfGuardExpr { }
		IndexExpr {
			return expr.pos
		}
		InfixExpr {
			left_pos := expr.left.position()
			right_pos := expr.right.position()
			if left_pos.pos == 0 || right_pos.pos == 0 {
				return expr.pos
			}
			return token.Position{
				line_nr: expr.pos.line_nr
				pos: left_pos.pos
				len: right_pos.pos - left_pos.pos + right_pos.len
			}
		}
		IntegerLiteral {
			return expr.pos
		}
		MapInit {
			return expr.pos
		}
		MatchExpr {
			return expr.pos
		}
		None {
			return expr.pos
		}
		PostfixExpr {
			return expr.pos
		}
		// ast.None { }
		PrefixExpr {
			return expr.pos
		}
		// ast.ParExpr { }
		SelectorExpr {
			return expr.pos
		}
		SizeOf {
			return expr.pos
		}
		StringLiteral {
			return expr.pos
		}
		StringInterLiteral {
			return expr.pos
		}
		// ast.Type { }
		StructInit {
			return expr.pos
		}
		Likely {
			return expr.pos
		}
		// ast.TypeOf { }
		else {
			return token.Position{}
		}
	}
}

pub fn (stmt Stmt) position() token.Position {
	match stmt {
		AssertStmt { return stmt.pos }
		AssignStmt { return stmt.pos }
		/*
		// Attr {
		// }
		// Block {
		// }
		// BranchStmt {
		// }
		*/
		CompIf { return stmt.pos }
		ConstDecl { return stmt.pos }
		/*
		// DeferStmt {
		// }
		*/
		EnumDecl { return stmt.pos }
		ExprStmt { return stmt.pos }
		FnDecl { return stmt.pos }
		ForCStmt { return stmt.pos }
		ForInStmt { return stmt.pos }
		ForStmt { return stmt.pos }
		/*
		// GlobalDecl {
		// }
		// GoStmt {
		// }
		// GotoLabel {
		// }
		// GotoStmt {
		// }
		// HashStmt {
		// }
		*/
		Import { return stmt.pos }
		/*
		// InterfaceDecl {
		// }
		// Module {
		// }
		*/
		Return { return stmt.pos }
		StructDecl { return stmt.pos }
		/*
		// TypeDecl {
		// }
		// UnsafeStmt {
		// }
		*/
		//
		else { return token.Position{} }
	}
}

// TODO: remove this fugly hack :-|
// fe2ex/1 and ex2fe/1 are used to convert back and forth from
// table.FExpr to ast.Expr , which in turn is needed to break
// a dependency cycle between v.ast and v.table, for the single
// field table.Field.default_expr, which should be ast.Expr
pub fn fe2ex(x table.FExpr) Expr {
	res := Expr{}
	C.memcpy(&res, &x, sizeof(Expr))
	return res
}

pub fn ex2fe(x Expr) table.FExpr {
	res := table.FExpr{}
	C.memcpy(&res, &x, sizeof(table.FExpr))
	return res
}
