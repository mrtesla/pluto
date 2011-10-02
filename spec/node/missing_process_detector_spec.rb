describe Pluto::Node::MissingProcessDetector do
  
  describe "#new" do
    
    let(:task_manager) do
      mock('task_manager')
    end
    
    let(:process_manager) do
      mock('process_manager')
    end
    
    it { described_class.new(task_manager, process_manager) }
    
  end
  
  describe "#call (without any tasks or processes)" do
    
    let(:task_manager) do
      tm = mock('task_manager')
      tm.should_receive(:tasks) { [] }
      tm
    end
    
    let(:process_manager) do
      pm = mock('process_manager')
      pm.should_receive(:processes) { [] }
      pm
    end
    
    subject { described_class.new(task_manager, process_manager) }
    before  { subject.call }
    it      { should have(0).missing_processes }
    
  end
  
  describe "#call (with some missing processes)" do
    
    let(:task_manager) do
      tm = mock('task_manager')
      tm.should_receive(:tasks) { [
        { 'PLUTO_PROC_UUID' => 'a' },
        { 'PLUTO_PROC_UUID' => 'b' },
        { 'PLUTO_PROC_UUID' => 'c' }
      ] }
      tm
    end
    
    let(:process_manager) do
      pm = mock('process_manager')
      pm.should_receive(:processes) { [
        { 'PLUTO_PROC_UUID' => 'a' },
        { 'PLUTO_PROC_UUID' => 'd' }
      ] }
      pm
    end
    
    subject { described_class.new(task_manager, process_manager) }
    before  { subject.call }
    it      { should have(2).missing_processes }
    its(:missing_processes) { should include({ 'PLUTO_PROC_UUID' => 'b' }) }
    its(:missing_processes) { should include({ 'PLUTO_PROC_UUID' => 'c' }) }
    
  end
  
end