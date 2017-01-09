PuppetLint.new_check(:use_ensure_packages) do
  TYPE_SEQUENCE_START = [
    # if ! defined ( Package[NAME])
    :IF, :NOT, :NAME, :LPAREN, :CLASSREF, :LBRACK, :SSTRING, :RBRACK, :RPAREN,
    # { package {NAME:
    :LBRACE, :NAME, :LBRACE, :SSTRING, :COLON
  ].freeze
  TYPE_SEQUENCE_END = [
    # } }
    :RBRACE, :RBRACE
  ].freeze
  VALUE_SEQUENCE = { 2 => 'defined', 4 => 'Package', 10 => 'package' }.freeze
  NAME_INDEX = 6

  OPTINAL_CONTENT = [
    { # ensure => installed
      sequence: [:NAME, :FARROW, :NAME],
      values: { 0 => 'ensure', 2 => 'installed' }
    },
    { # ensure => installed;
      sequence: [:NAME, :FARROW, :NAME, :SEMIC],
      values: { 0 => 'ensure', 2 => 'installed' }
    },
    { # ensure => present
      sequence: [:NAME, :FARROW, :NAME],
      values: { 0 => 'ensure', 2 => 'present' }
    },
    { # ensure => present;
      sequence: [:NAME, :FARROW, :NAME, :SEMIC],
      values: { 0 => 'ensure', 2 => 'present' }
    }
  ].freeze

  FORMATTING_TOKENS = PuppetLint::Lexer::FORMATTING_TOKENS

  def check
    if_indexes.each do |cond|
      next if check_if(cond)

      notify :warning,
             message: 'ensure_packages should be used',
             line: cond[:tokens].first.line,
             column: cond[:tokens].first.column
    end
  end

  def check_if(cond)
    tokens = filter_code_tokens(cond[:tokens])

    # Test start of patterns
    return true unless match_tokens(tokens, TYPE_SEQUENCE_START, VALUE_SEQUENCE)

    # Test end of pattern
    return true unless match_tokens(tokens.last(2), TYPE_SEQUENCE_END, {})

    tokens = tokens.slice(Range.new(TYPE_SEQUENCE_START.size,
                                    -TYPE_SEQUENCE_END.size - 1))

    return false if tokens.empty?

    return true unless OPTINAL_CONTENT.index do |c|
      match_tokens(tokens, c[:sequence], c[:values])
    end

    false
  end

  def match_tokens(tokens, type, value)
    tokens.first(type.size).map(&:type) == type &&
      value.values == value.keys.map { |i| tokens[i].value }
  end

  def fix(problem)
    cond = if_indexes.select do |c|
      c[:tokens].first.line == problem[:line] &&
        c[:tokens].first.column == problem[:column]
    end.first

    package_name = filter_code_tokens(cond[:tokens])[NAME_INDEX].value

    remove_tokens(cond[:start], cond[:end])

    new_tokens = ensure_packages_tokens(package_name)

    insert_tokens(cond[:start], new_tokens)

    PuppetLint::Data.tokens = tokens

    merge_if_possible(cond[:start])
  end

  def merge_if_possible(idx)
    target = PuppetLint::Data.function_indexes.keep_if do |func|
      func[:tokens].first.type == :NAME &&
        func[:tokens].first.value == 'ensure_packages' &&
        func[:tokens].last.next_code_token == tokens[idx] &&
        func[:tokens].last.next_code_token != func[:tokens].first
    end

    return if target.empty?

    start_idx = tokens.first(idx).rindex { |t| t.type == :SSTRING } + 1

    remove_tokens(start_idx, idx + 2)
    insert_tokens(start_idx, [PuppetLint::Lexer::Token.new(:COMMA, ',', 0, 0)])
  end

  def tokens_idx(obj)
    tokens.index(obj)
  end

  def remove_tokens(from, to)
    num = to - from + 1
    tokens.slice!(from, num)
    fix_linked_list
  end

  def insert_tokens(idx, new_tokens)
    tokens.insert(idx, *new_tokens)
    fix_linked_list
  end

  def ensure_packages_tokens(name)
    [
      PuppetLint::Lexer::Token.new(:NAME, 'ensure_packages', nil, nil),
      PuppetLint::Lexer::Token.new(:LPAREN, '(', nil, nil),
      PuppetLint::Lexer::Token.new(:LBRACK, '[', nil, nil),
      PuppetLint::Lexer::Token.new(:SSTRING, name, nil, nil),
      PuppetLint::Lexer::Token.new(:RBRACK, ']', nil, nil),
      PuppetLint::Lexer::Token.new(:RPAREN, ')', nil, nil)
    ]
  end

  def fix_linked_list
    tokens.each_cons(2) do |a, b|
      a.next_token = b
      b.prev_token = a
    end

    filter_formating_tokens(tokens).each_cons(2) do |a, b|
      a.next_code_token = b
      b.prev_code_token = a
    end
  end

  def filter_code_tokens(tokens)
    tokens.delete_if { |token| FORMATTING_TOKENS.key? token.type }
  end

  def filter_formating_tokens(tokens)
    tokens.select { |token| !FORMATTING_TOKENS.key? token.type }
  end

  def if_indexes
    PuppetLint::Data.definition_indexes(:IF)
  end
end
