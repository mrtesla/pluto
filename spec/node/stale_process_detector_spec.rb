describe Pluto::Node::StaleProcessDetector do
  
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
    it      { should have(0).stale_processes }
    
  end
  
  describe "#call (with some stale processes)" do
    
    let(:task_manager) do
      tm = mock('task_manager')
      tm.should_receive(:tasks) { [
        { 'PLUTO_PROC_UUID' => 'a' },
        { 'PLUTO_PROC_UUID' => 'b' }
      ] }
      tm
    end
    
    let(:process_manager) do
      pm = mock('process_manager')
      pm.should_receive(:processes) { [
        { 'PLUTO_PROC_UUID' => 'a' },
        { 'PLUTO_PROC_UUID' => 'c' },
        { 'PLUTO_PROC_UUID' => 'd' }
      ] }
      pm
    end
    
    subject { described_class.new(task_manager, process_manager) }
    before  { subject.call }
    it      { should have(2).stale_processes }
    its(:stale_processes) { should include({ 'PLUTO_PROC_UUID' => 'c' }) }
    its(:stale_processes) { should include({ 'PLUTO_PROC_UUID' => 'd' }) }
    
  end
  
end