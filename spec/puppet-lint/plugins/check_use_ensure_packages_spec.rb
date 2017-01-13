require 'spec_helper'

describe 'use_ensure_packages' do
  context 'with fix disabled' do
    context 'if not defined package' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': }
        }"
      end

      it 'should detect the problem' do
        expect(problems).to have(1).problems
      end
    end

    context 'if not defined package ensure installed' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': ensure => installed }
        }"
      end

      it 'should detect the problem' do
        expect(problems).to have(1).problems
      end
    end

    context 'if not defined package ensure installed' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': ensure => installed; }
        }"
      end

      it 'should detect the problem' do
        expect(problems).to have(1).problems
      end
    end

    context 'if not defined package ensure installed' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': ensure => present }
        }"
      end

      it 'should detect the problem' do
        expect(problems).to have(1).problems
      end
    end

    context 'if not defined package ensure installed' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': ensure => present; }
        }"
      end

      it 'should detect the problem' do
        expect(problems).to have(1).problems
      end
    end

    context 'if not defined package w/ notify' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': ensure => present, notify => Service['apache2'];}
        }"
      end

      it 'should not detect any problem' do
        expect(problems).to have(0).problems
      end
    end

    context 'if not defined package w/ else' do
      let(:code) do
        "if ! defined (Package['foo']) {
           package {'foo': ensure => present; }
         } else {
           package {'bar': ensure => present; }
         }"
      end

      it 'should not detect any problem' do
        expect(problems).to have(0).problems
      end
    end

    context 'if not defined package w/ elsis' do
      let(:code) do
        "if ! defined (Package['foo']) {
           package {'foo': ensure => present; }
         } elsif ! defined (Package['bar']) {
           package {'bar': ensure => present; }
         }"
      end

      it 'should not detect any problem' do
        expect(problems).to have(0).problems
      end
    end

    context 'if not defined package twice' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': }
        }
        use { 'foo': }
        if ! defined (Package['bar']) {
          package {'bar': }
        }"
      end

      it 'should detect the problem' do
        expect(problems).to have(2).problems
      end
    end

    context 'if not defined file' do
      let(:code) do
        "if ! defined (File['foo']) {
          File {'foo': }
        }"
      end

      it 'should not detect any problem' do
        expect(problems).to have(0).problems
      end
    end
  end

  context 'with fix enabled' do
    before do
      PuppetLint.configuration.fix = true
    end

    after do
      PuppetLint.configuration.fix = false
    end

    context 'if not defined package' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': }
        }"
      end
      let(:expected_code) do
        "ensure_packages(['foo'])"
      end

      it 'should solve the problem' do
        expect(manifest).to eq(expected_code)
      end
    end

    context 'if not defined package ensure installed' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': ensure => installed }
        }"
      end
      let(:expected_code) do
        "ensure_packages(['foo'])"
      end

      it 'should solve the problem' do
        expect(manifest).to eq(expected_code)
      end
    end

    context 'if not defined package twice' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': }
        }
        use { 'foo': }
        if ! defined (Package['bar']) {
          package {'bar': }
        }"
      end
      let(:expected_code) do
        "ensure_packages(['foo'])
        use { 'foo': }
        ensure_packages(['bar'])"
      end

      it 'should solve the problem' do
        expect(manifest).to eq(expected_code)
      end
    end

    context 'merge generated ensure_packages statements' do
      let(:code) do
        "if ! defined (Package['foo']) {
          package {'foo': }
        }
        if ! defined (Package['bar']) {
          package {'bar': }
        }"
      end
      let(:expected_code) do
        "ensure_packages(['foo','bar'])"
      end

      it 'should solve the problem' do
        expect(manifest).to eq(expected_code)
      end
    end

    context 'merge to pre existing ensure_packages' do
      let(:code) do
        "ensure_packages(['foo'])
        if ! defined (Package['bar']) {
          package {'bar': }
        }"
      end
      let(:expected_code) do
        "ensure_packages(['foo','bar'])"
      end

      it 'should solve the problem' do
        expect(manifest).to eq(expected_code)
      end
    end

    context 'do not merge to pre existing ensure_packages with arguments' do
      let(:code) do
        "ensure_packages(['foo'], {'ensure' => 'present'})
         if ! defined (Package['bar']) {
           package {'bar': }
         }"
      end
      let(:expected_code) do
        "ensure_packages(['foo'], {'ensure' => 'present'})
         ensure_packages(['bar'])"
      end

      it 'should solve the problem' do
        expect(manifest).to eq(expected_code)
      end
    end
  end
end
