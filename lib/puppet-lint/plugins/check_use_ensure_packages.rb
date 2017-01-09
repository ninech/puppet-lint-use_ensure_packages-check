PuppetLint.new_check(:use_ensure_packages) do

  TYPE_SEQUENCE = [
    :IF, :NOT, :NAME, :LPAREN, :CLASSREF, :LBRACK, :SSTRING, :RBRACK, :RPAREN,
    :LBRACE, :NAME, :LBRACE, :SSTRING, :COLON, :RBRACE, :RBRACE
  ]
  VALUE_SEQUENCE = { 2 => 'defined', 4 => 'Package', 10 => 'package'}
  PACKAGE_NAME_INDEX = 6

  def check
    if_indexes.each do |cond|
      tokens = filter_code_tokens(cond[:tokens])
      next unless tokens.first(TYPE_SEQUENCE.length).map(&:type) == TYPE_SEQUENCE

      next unless VALUE_SEQUENCE.values == VALUE_SEQUENCE.keys.map { |i| tokens[i].value }

      notify :warning, {
        :message => 'ensure_packages should be used',
        :line    => cond[:tokens].first.line,
        :column  => cond[:tokens].first.column,
      }
    end
  end

  def fix(problem)
    cond = if_indexes.select do |cond|
      cond[:tokens].first.line == problem[:line] and cond[:tokens].first.column == problem[:column]
    end.first

    package_name = filter_code_tokens(cond[:tokens])[PACKAGE_NAME_INDEX].value

    new_tokens = [
      PuppetLint::Lexer::Token.new(:NAME, 'ensure_packages', nil, nil),
      PuppetLint::Lexer::Token.new(:LPAREN, '(', nil, nil),
      PuppetLint::Lexer::Token.new(:LBRACK, '[', nil, nil),
      PuppetLint::Lexer::Token.new(:SSTRING, package_name, nil, nil),
      PuppetLint::Lexer::Token.new(:RBRACK, ']', nil, nil),
      PuppetLint::Lexer::Token.new(:RPAREN, ')', nil, nil),
    ]

    replace_offset = cond[:start]
    replace_length = cond[:end] - cond[:start] + 1

    tokens.slice!(replace_offset, replace_length)
    tokens.insert(replace_offset, *new_tokens)
  end

  def filter_code_tokens(tokens)
    tokens.delete_if { |token| PuppetLint::Lexer::FORMATTING_TOKENS.has_key? token.type }
  end

  def if_indexes
    PuppetLint::Data.definition_indexes(:IF)
  end
end
