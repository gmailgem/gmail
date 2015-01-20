require 'spec_helper'

describe Gmail::Labels do
  context '#localize' do
    context 'when given the XLIST flag ' do
      [:Inbox, :All, :Drafts, :Sent, :Trash, :Important, :Junk, :Flagged].each do |flag|
        context flag do
          it 'localizes into the appropriate label' do
            localized = ""
            mock_client { |client| localized = client.labels.localize(flag) }
            expect(localized).to be_a_kind_of(String)
            expect(localized).to match(/\[Gmail|Google Mail\]|Inbox/i)
          end
        end
      end
    end
  end
end
