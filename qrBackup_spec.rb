
require 'rspec'
require 'tmpdir'

require_relative 'qrBackup.rb'

describe QrBackup do
  describe '.backup' do
    context 'with wrong number of arguments' do
      it{expect { QrBackup.backup }.to raise_error}
      it{ expect {QrBackup.backup(1)}.to raise_error}
      it { expect {QrBackup.backup(1,2,3,4)}.to raise_error}
    end

    context 'with invalid input' do
      it { expect {QrBackup.backup(nil, "7593CB6D")}.to raise_error}
    end

    context 'with no string as id' do
      it {expect {QrBackup.backup("testfile", 42)}.to raise_error}
    end

    context 'with valid input' do
      it { expect(QrBackup.backup("testfile", :id => "7593CB6D")).to eq("testfile.pdf")}
      it { expect(QrBackup.backup("testfile", :encrypt => false)).to eq("testfile.pdf")}
    end
  end

  describe '.encrypt' do
    context 'whith wrong number of arguments' do
      it { expect { QrBackup.encrypt}.to raise_error}
      it {expect {QrBackup.encrypt(1,2,3)}.to raise_error}
    end

    context 'with no valid file name' do
      it {expect {QrBackup.encrypt(nil, '7593CB6D')}.to raise_error}
    end

    context 'with no valid gpg id' do
      it {expect {QrBackup.encrypt('testfile', nil)}.to raise_error}
    end

    context 'with valid input' do
      out = QrBackup.encrypt('testfile', '7593CB6D')
      # comparison = ""
      # File.open('testfile', 'r') do |f|
      #   f.each_line do |l|
      #     comparison += l
      #   end
      # end

      it do
        expect(out).to be_a(String)
      end
      # it do
      #   expect(out).to eq(comparison)
      # end
    end
  end
  
  describe '.createQr' do
    context 'with wrong number of arguments' do
      it { expect {QrBackup.createQr()}.to raise_error}
      it { expect {QrBackup.createQr(1,2,3,4)}.to raise_error}
    end

    context 'with input not of type string' do
      it {expect {QrBackup.createQr(nil)}.to raise_error}
    end

    context 'if invalid directory is given' do
      Dir.mktmpdir do |dir|
        it {expect {QrBackup.createQr("Test", :dir => "#{dir}/mimblwimbl")}.to raise_error}
      end
    end

    context 'if invalid prefix is given' do
      it { expect {QrBackup.createQr("Test", :prefix => 42)}.to raise_error}
    end

    context 'if invalid size is given' do
      it {expect {QrBackup.createQr("Test", :size => "abc")}.to raise_error}
      it {expect {QrBackup.createQr("Test", :size => -5)}.to raise_error}
    end

    context 'if valid input' do
      it { expect(QrBackup.createQr("Test")).to be_a(Array)}
      File.delete("qr0.png") if File.file?("qr0.png")
    end

    context 'if input < size' do
      it { expect(QrBackup.createQr("Test\nTest").length).to eq(1)}
    end
    
    context 'if long input' do
      input = "1\n2\n3\n4"
      it {expect(QrBackup.createQr(input, :size => 1).length).to eq(5)}
      (0..3).each do |i|
        if File.file?("qr#{i}.png") then
          File.delete("qr#{i}.png")
        end
      end
    end
      
  end
end
