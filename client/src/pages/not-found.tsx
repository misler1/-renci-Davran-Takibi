import { Link } from "wouter";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Home, AlertTriangle } from "lucide-react";

export default function NotFound() {
  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-slate-50 p-4">
      <Card className="w-full max-w-md shadow-xl text-center p-8 rounded-2xl border-white/50 bg-white/80 backdrop-blur">
        <CardContent className="space-y-6 pt-6">
          <div className="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto">
            <AlertTriangle className="w-10 h-10 text-red-500" />
          </div>
          
          <div className="space-y-2">
            <h1 className="text-4xl font-display font-bold text-slate-900">404</h1>
            <p className="text-lg text-slate-600 font-medium">Page Not Found</p>
            <p className="text-slate-400">The page you're looking for doesn't exist or has been moved.</p>
          </div>

          <Link href="/">
            <Button className="w-full h-12 rounded-xl bg-slate-900 hover:bg-slate-800 text-white gap-2 mt-4">
              <Home className="w-4 h-4" />
              Return to Dashboard
            </Button>
          </Link>
        </CardContent>
      </Card>
    </div>
  );
}
