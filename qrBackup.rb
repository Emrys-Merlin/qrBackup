#!/usr/bin/ruby
#
# QrBackup takes a text-file (input) and a pgp-key (id). Then it
# encrypts the text with the key, cuts the encrypted text to pieces and
# generates QR-Codes of them, which then land in a .pdf file for you to print. 

# gpg api
require 'gpgme'

# generats pdfs
require 'prawn'

require 'tmpdir'

class QrBackup

  # This method creates the pdf. It takes the input-file, a gpg-id and
  # an optional description. Returns pdf location.
  def self.backup(input, options = {})
    description = options[:description] || nil
    encrypt = (options[:encrypt].nil? || options[:encrypt]) && true
    id = options[:id] || nil
    
    # Valid input?
    if not input.is_a? String then
      raise ArgumentError, "input needs to be a string."
    end

    if not File.file?(input) then
      raise ArgumentError, "input needs to be a valid filename."
    end
    
    if !!encrypt != encrypt then
      raise ArgumentError, "encrypt needs to be a boolean."
    end

    if encrypt and (not id.is_a? String) then
      raise ArgumentError, "id needs to be a string."
    end

    # encrypt the text
    if encrypt then
      encrypted = self.encrypt(input, id)
    else
      if not File.file?(input)
        raise ArgumentError, "input needs to be a valid file."
      end
      encrypted = ""
      File.open(input) do |f|
        f.each_line do |l|
          encrypted += l
        end
      end
    end

    # output file name
    # TODO: output filename as optional argument
    output = "#{input}.pdf"
    
    Dir.mktmpdir do |dir|

      # array with filenames of the qrcodes
      qrs = self.createQr(encrypted, :dir => dir)

      # pdf creation
      Prawn::Document.generate(output) do

        # page layout
        define_grid(:columns => 5, :rows => 8, :gutter => 10)
        
        len = qrs.length
        time = Time.now
        
        (0..len).each do |i|

          # header
          grid([0,0], [0,4]).bounding_box do
            font_size 20 do
              text "qrBackup of file \"#{input}\"", :align => :center, :style => :bold
            end
            font_size 14 do
              text "#{time}", :align => :center
            end
          end

          # body
          grid([1,0], [6,4]).bounding_box do
            if i == 0 then
              unless description.nil? then
                text "Descripton:\n\n", :style => :bold
                text description
                text "\n\n"
              end
              
              text "Data:\n\n", :style => :bold
              text encrypted
            else
              image "#{qrs[i-1]}", :position => :center, :vposition => :center
            end
          end

          # footer
          grid([7,0], [7,4]).bounding_box do
            text "#{i+1}/#{len+1}", :align => :center
          end

          start_new_page unless i == len
        end
      end
    end

    return output
  end

  # Takes an inputfile and a gpg id and encrypts the input with the
  # key. The encrypted text is returned as a string.
  # TODO: Implement multiple keys
  # TODO: input could be given as string
  # TODO: output could be written to file directly
  def self.encrypt(input, id)

    # Enforce valid input.
    if not File.file?(input) then
      raise ArgumentError, "#{input} is not a file or does not exist."
    end

    if GPGME::Key.find(:public, id).length != 1 then
      raise ArgumentError, "#{id} is not a valid gpg id."
    end

    # Crypto
    crypto = GPGME::Crypto.new
    out = crypto.encrypt File.open(input), :recipients => id, :armor => true

    return out.to_s
  end

  # Takes an input string and turns it into QR-Codes. You can give it
  # a directory, where the Codes are saved, a prefix for the
  # file-names and a size, which measures after how many lines of the
  # input you start with a new QR-Code.
  def self.createQr(input, opts = {})
    dir = opts[:dir] || "."
    size = opts[:size] || 10
    prefix = opts[:prefix] || "qr"

    # Enforce valid input.
    if not input.is_a? String then
      raise ArgumentError, "input must be a String."
    end
    
    if (not size.is_a? Integer) or size <= 0 then
      raise ArgumentError, ":size must be a positive int."
    end

    if not File.directory?(dir) then
      raise ArgumentError, ":dir must be a valid directory"
    end

    if not prefix.is_a? String then
      raise ArgumentError, ":prefix must be a String."
    end

    
    out = []

    count = input.lines.length
    ratio = count/size
       
    (0..ratio).each do |i|

      if (i+1)*size > input.lines.length then
        tmp = input.lines[i*size..input.lines.length-1].inject(:+)
      else
        tmp = input.lines[i*size..((i+1)*size-1)].inject(:+)
      end
      
      out << ("#{dir}/#{prefix}#{i}.png")
      
      # HACK: We use a commandline tool here and check at the same
      #   time, that it is installed or something... It would be cool
      #   to use a ruby intern solution. However it seemed to me, that
      #   rqrcode and rqrcode-png do not have enough options. I did not
      #   look for other solutions however.
      if system `qrencode -o #{out.last} -- \"#{tmp}\"` then
        raise "Please install 'qrencode'."
      end
      
    end

    return out
  end
end


if __FILE__ == $0 then
  if ARGV.length == 0 or ARGV.length > 2 then
    puts "qrBackup.rb version 0.0.1~alpha"
    puts "usage:"
    puts "qrBackup.rb file [keyid]"
    puts "If keyid is present, the text will be encrypted. Otherwise the pdf will be created with the unencrypted input."
  elsif ARGV.length == 2 then
    puts "Generating backup #{QrBackup.backup(ARGV[0].to_s, :id => ARGV[1].to_s)}"
  else
    puts "Generating backup #{QrBackup.backup(ARGV[0].to_s, :encrypt => false)}"
  end
end
  
