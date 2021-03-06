grammar GroupFile;

options { language = Ruby; }

@parser::header {
module ANTLR3
module Template
}

@lexer::header {
module ANTLR3
module Template
}

@lexer::footer {
end # module Template
end # module ANTLR3
}

@parser::footer {
end # module Template
end # module ANTLR3
}

@parser::main {
  defined?(ANTLR3::Template::GroupFile::Lexer) or require 'antlr3/template/group-file'
  ANTLR3::Template::GroupFile::Parser.main( ARGV )
}

@parser::members {
  def fetch_group( namespace, name )
    if namespace.const_defined?( name )
      group = namespace.const_get( name )
      unless group.is_a?( ANTLR3::Template::Group )
      
      end
    else
      group = ANTLR3::Template::Group.new
      namespace.const_set( name, group )
    end
    return( group )
  end
  
  def unescape( text )
    text.gsub( /\\(?:([abefnrstv])|([0-7]{3})|x([0-9a-fA-F]{2})|(.))/ ) do
      if $1
        case $1[0]
        when ?a then "\a"
        when ?b then "\b"
        when ?e then "\e"
        when ?f then "\f"
        when ?n then "\n"
        when ?r then "\r"
        when ?s then "\s"
        when ?t then "\t"
        when ?v then "\v"
        end
      elsif $2 then $2.to_i( 8 ).chr
      elsif $3 then $3.to_i( 16 ).chr
      elsif $4 then $4
      end
    end
  end
  
  def extract_template( token )
    case token.type
    when TEMPLATE
      token.text.gsub( /\A<<<\r?\n?|\r?\n?>>>\Z/, '' )
    when STRING
      unescape( token.text[1...-1] )
    end
  end
  
  def group( namespace = ::Object )
    group_spec( namespace )
  end
}

group_spec[ namespace ] returns [ group ]
  : ( group_name[ $namespace ] { $group = $group_name.group }
    | { $group = ANTLR3::Template::Group.new }
    )
    member[ $group ]*
  ;

group_name[ namespace ] returns [ group ]
  : 'group'
    (
      mod=CONSTANT '::'
      { namespace = namespace.const_get( $mod.text ) }
    )*
    name=CONSTANT { $group = fetch_group( namespace, $name.text ) }
    ';'?
  ;

member[ group ]
@init { params = nil }
  : name=ID ( parameter_declaration { params = $parameter_declaration.list } )? '::='
    ( aliased=ID { $group.alias_template( $name.text, $aliased.text ) }
    | TEMPLATE   { $group.define_template( $name.text, extract_template( $TEMPLATE ), params ) }
    | STRING     { $group.define_template( $name.text, extract_template( $STRING ), params ) }
    )
  ;

parameter_declaration returns [ list ]
@init { $list = nil }
  : '(' ( parameters { $list = $parameters.list } )? ')'
  | parameters { $list = $parameters.list }
  ;

parameters returns [ list ]
@init { $list = ANTLR3::Template::ParameterList.new }
  : parameter[ $list ] ( ',' parameter[ $list ] )*
  ;

parameter[ parameters ]
  : '*' name=ID { $parameters.splat = $name.text }
  | '&' name=ID { $parameters.block = $name.text }
  | name=ID     { param = ANTLR3::Template::Parameter.new( $name.text ) }
    ( '=' v=STRING { param.default = $v.text } )?
    { $parameters.add( param ) }
  ;

CONSTANT
  : 'A'..'Z' ( 'a'..'z' | '_' | 'A'..'Z' | '0'..'9' )*
  ;

ID
  : ( 'a'..'z' | '_' )
    ( 'a'..'z' | '_' | 'A'..'Z' | '0'..'9' )*
  ;

TEMPLATE
  : '<<<'
    (options { greedy = false; }: '\\' . | . )*
    '>>>'
  ;

STRING
  : '"'  ( ~( '\\' | '"' )  | '\\' . )* '"'
  | '\'' ( ~( '\\' | '\'' ) | '\\' . )* '\''
  ;

COMMENT
@after { skip }
  : ( '#' | '//' ) ~'\n'*
  | '/*' .* '*/'
  ;

WS
  : ( ' ' | '\t' | '\n' | '\r' | '\f' )+ { skip }
  ;