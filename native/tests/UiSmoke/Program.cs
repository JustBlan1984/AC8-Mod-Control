using AC8ModControl;
internal static class UiSmoke
{
 [STAThread] static void Main(string[] args)
 {
  ApplicationConfiguration.Initialize();
  using var form=new LauncherForm();
  form.ClientSize=new Size(840,1500);
  form.ShowInTaskbar=false;
  form.Opacity=0;
  form.Shown+=(_,_)=> {
    form.PerformLayout();
    using var bitmap=new Bitmap(form.Width,form.Height);
    form.DrawToBitmap(bitmap,new Rectangle(0,0,form.Width,form.Height));
    bitmap.Save(args[0]);
    form.Close();
  };
  Application.Run(form);
 }
}
