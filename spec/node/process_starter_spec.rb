describe Pluto::Node::ProcessStarter do
  
  describe "#new" do
    
    let(:missing_process_detector) do
      mock('missing_process_detector')
    end
    
    let(:process_manager) do
      mock('process_manager')
    end
    
    it { described_class.new(process_manager, missing_process_detector) }
    
  end
  
end
