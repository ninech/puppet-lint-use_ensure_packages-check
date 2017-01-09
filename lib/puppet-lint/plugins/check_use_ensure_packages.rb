PuppetLint.new_check(:use_ensure_packages) do

  TYPE_SEQUENCE_START = [
    # if ! defined ( Package[NAME])
    :IF, :NOT, :NAME, :LPAREN, :CLASSREF, :LBRACK, :SSTRING, :RBRACK, :RPAREN,
    # { package {NAME:
    :LBRACE, :NAME, :LBRACE, :SSTRING, :COLON
  ]
  TYPE_SEQUENCE_END = [
    # } }
    :RBRACE, :RBRACE
  ]
  VALUE_SEQUENCE = { 2 => 'defined', 4 => 'Package', 10 => 'package'}
  NAME_INDEX = 6

  OPTINAL_CONTENT = [
    { # ensure => installed
      sequence: [:NAME, :FARROW, :NAME],
      values: { 0 => 'ensure', 2 => 'installed'},
    },
    { # ensure => installed;
      sequence: [:NAME, :FARROW, :NAME, :SEMIC],
      values: { 0 => 'ensure', 2 => 'installed'},
    },
    { # ensure => present
      sequence: [:NAME, :FARROW, :NAME],
      values: { 0 => 'ensure', 2 => 'present'},
    },
    { # ensure => present;
      sequence: [:NAME, :FARROW, :NAME, :SEMIC],
      values: { 0 => 'ensure', 2 => 'present'},
    },
  ]

  FORMATTING_TOKENS = PuppetLint::Lexer::FORMATTING_TOKENS

  def check
    if_indexes.each do |cond|
      tokens = filter_code_tokens(cond[:tokens])

      # Test start of patterns
      next unless tokens.first(TYPE_SEQUENCE_START.size).map(&:type) == TYPE_SEQUENCE_START
      next unless VALUE_SEQUENCE.values == VALUE_SEQUENCE.keys.map { |i| tokens[i].value }

      # Test end of pattern
      next unless tokens.last(TYPE_SEQUENCE_END.size).map(&:type) == TYPE_SEQUENCE_END

      if tokens.length == (TYPE_SEQUENCE_START.size + TYPE_SEQUENCE_END.size)
        notify :warning, {
          :message => 'ensure_packages should be used',
          :line    => cond[:tokens].first.line,
          :column  => cond[:tokens].first.column,
        }
      else
        tokens = tokens.slice(Range.new(TYPE_SEQUENCE_START.size, -TYPE_SEQUENCE_END.size-1))
        OPTINAL_CONTENT.each do |c|
          next unless tokens.map(&:type) == c[:sequence]
          next unless c[:values].values == c[:values].keys.map { |i| tokens[i].value }

          notify :warning, {
            :message => 'ensure_packages should be used',
            :line    => cond[:tokens].first.line,
            :column  => cond[:tokens].first.column,
          }

          break
        end
      end
    end
  end

  def fix(problem)
    cond = if_indexes.select do |cond|
      cond[:tokens].first.line == problem[:line] and cond[:tokens].first.column == problem[:column]
    end.first

    prev_ensure_packages = PuppetLint::Data.function_indexes.keep_if do |func|
      func[:tokens].first.value == 'ensure_packages' and
      func[:tokens].last == cond[:tokens].first.prev_code_token
    end.first

    package_name = filter_code_tokens(cond[:tokens])[NAME_INDEX].value

    unless prev_ensure_packages.nil?
      delete_offset = tokens_idx(cond[:tokens].first.prev_code_token)+1
    else
      delete_offset = cond[:start]
    end

    delete_length = cond[:end] - delete_offset + 1

    remove_tokens(delete_offset, delete_length)


    unless prev_ensure_packages.nil?
      insert_offset = tokens_idx(prev_ensure_packages[:tokens].last)
      insert_offset = tokens.first(insert_offset).rindex { |t| t.type == :SSTRING } + 1

      new_tokens = [
        PuppetLint::Lexer::Token.new(:COMMA, ',', nil, nil),
        PuppetLint::Lexer::Token.new(:SSTRING, package_name, nil, nil),
      ]
    else
      insert_offset = cond[:start]

      new_tokens = [
        PuppetLint::Lexer::Token.new(:NAME, 'ensure_packages', nil, nil),
        PuppetLint::Lexer::Token.new(:LPAREN, '(', nil, nil),
        PuppetLint::Lexer::Token.new(:LBRACK, '[', nil, nil),
        PuppetLint::Lexer::Token.new(:SSTRING, package_name, nil, nil),
        PuppetLint::Lexer::Token.new(:RBRACK, ']', nil, nil),
        PuppetLint::Lexer::Token.new(:RPAREN, ')', nil, nil),
      ]
    end


    insert_tokens(insert_offset, new_tokens)


    PuppetLint::Data.tokens = tokens
  end

  def tokens_idx(obj)
    tokens.index(obj)
  end

  def remove_tokens(from, num)
    tokens.slice!(from, num)
    fix_linked_list(from-1, 2)
  end

  def insert_tokens(idx, new_tokens)
    tokens.insert(idx, *new_tokens)
    fix_linked_list(idx, tokens.size)
  end

  def fix_linked_list(from, to)
    Range.new(from,to-from).each do |idx|
      if idx > 0
        tokens[idx].prev_token = tokens[idx-1]
        unless FORMATTING_TOKENS.include?(tokens[idx].type)
          prev_nf_idx = tokens.first(idx).rindex { |r| ! FORMATTING_TOKENS.include? r.type }
          unless prev_nf_idx.nil?
            tokens[prev_nf_idx].next_code_token = tokens[idx]
            tokens[idx].prev_code_token = tokens[prev_nf_idx]
          end
        end
      end
      if idx < tokens.length
        tokens[idx].next_token = tokens[idx+1]
        unless FORMATTING_TOKENS.include?(tokens[idx].type)
          next_nf_idx = tokens.last(tokens.size-idx).index { |r| ! FORMATTING_TOKENS.include? r.type }
          unless next_nf_idx.nil?
            tokens[next_nf_idx].prev_code_token = tokens[idx]
            tokens[idx].next_code_token = tokens[next_nf_idx]
          end
        end
      end
    end
  end

  def filter_code_tokens(tokens)
    tokens.delete_if { |token| PuppetLint::Lexer::FORMATTING_TOKENS.has_key? token.type }
  end

  def if_indexes
    PuppetLint::Data.definition_indexes(:IF)
  end
end
