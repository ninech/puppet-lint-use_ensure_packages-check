require 'spec_helper'

describe 'use_ensure_packages' do
  context 'with fix disabled' do
    context 'if not defined package' do
      let(:code) { "
        if ! defined (Package['foo']) {
          package {'foo': }
        }
      " }

      it 'should detect the problem' do
        expect(problems).to have(1).problems
      end
    end

    context 'if not defined package twice' do
      let(:code) { "
        if ! defined (Package['foo']) {
          package {'foo': }
        }
        use { 'foo': }
        if ! defined (Package['bar']) {
          package {'bar': }
        }
      " }

      it 'should detect the problem' do
        expect(problems).to have(2).problems
      end
    end

    context 'if not defined file' do
      let(:code) { "
        if ! defined (File['foo']) {
          File {'foo': }
        }
      " }

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
      let(:code) { "
        if ! defined (Package['foo']) {
          package {'foo': }
        }
      " }
      let(:expected_code) { "
        ensure_packages(['foo'])
      " }

      it 'should solve the problem' do
        expect(manifest).to eq(expected_code)
      end
    end

    context 'if not defined package twice' do
      let(:code) { "
        if ! defined (Package['foo']) {
          package {'foo': }
        }
        use { 'foo': }
        if ! defined (Package['bar']) {
          package {'bar': }
        }
      " }
      let(:expected_code) { "
        ensure_packages(['foo'])
        use { 'foo': }
        ensure_packages(['bar'])
      " }

      it 'should solve the problem' do
        expect(manifest).to eq(expected_code)
      end
    end
  end
end
