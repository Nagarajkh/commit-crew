import { Bug, ChevronRight, CircleCheck } from 'lucide-react';

export default function FeedbackSection() {
  return (
    <section className="feedback-card">
      <div className="section-kicker"><Bug size={14} /> Feedback loop</div>
      <div className="feedback-copy">
        <div>
          <h2>Make the next round smarter</h2>
          <p>Capture what happened on the floor so every disruption improves the next plan.</p>
        </div>
        <button className="outline-button">Share feedback <ChevronRight size={15} /></button>
      </div>
      <div className="feedback-status"><CircleCheck size={15} /> 12 observations resolved this week <span>•</span> 94% coordinator confidence</div>
    </section>
  );
}
