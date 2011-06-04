#
#   Copyright 2008-1011 Antoine Toulme
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

$:.unshift File.dirname(__FILE__)

module Manifest

  MANIFEST_LINE_SEP = /\r\n|\n|\r[^\n]/
  MANIFEST_SECTION_SEP = /(#{MANIFEST_LINE_SEP}){2}/

  def read(text)

    text.split(MANIFEST_SECTION_SEP).reject { |s| s.chomp == "" }.map do |section|
      section.split(MANIFEST_LINE_SEP).each { |line| line.length < 72 }.inject([]) { |merged, line|
        if line[0] == ' '
          merged.last << line[1..-1]
        else
          merged << line
        end
        merged
        }.map { |line| line.split(/: /) }.inject({}) { |map, (name, values)|
          if (values.nil?)
            map.merge!(name=>nil)
          else
            valuesAsHash = {}
            
            nestedList = false
            values.split(/,/).inject([]) { |array, att1| 
              # split and then recompose. Not optimal at all but the manifest format is such a pain...
              if nestedList
                last = array.pop
                array << "#{last},#{att1}"
              else
                array << att1
              end

              index = 0
              if (/.*"$/.match(att1) || /.*";/.match(att1))
                 nestedList = false
                 index =  $~[0].size
              end
              if att1[index, att1.size].match(/"/)
                 # if a " is in the value, it means we entered a subentry. And since it is not at the
                 # end of the line, we can conclude we are in a nested list.
                 nestedList = true
              end
              
              array
              }.each { |attribute|
                optionalAttributes = {}
                values = attribute.split(/;/)
                value = values.shift
                values.each {|attribute| 
                  array = attribute.split(/:?=/) 
                  optionalAttributes.merge!(array.first.strip=>array.last.strip)
                }
                valuesAsHash.merge!(value=>optionalAttributes)
              }
              map.merge!(name=>valuesAsHash) 
            end
          }
        end
      end

      module_function :read
    end
