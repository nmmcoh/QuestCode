using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

public static class MyQuestCode
{
    public static void Main()
    {
        double initialGuess = 10;

        double upperLimit = 200;
        double tGuess = Math.Log10(initialGuess / upperLimit);
        double tGuessSd = 0.2;
        double beta = 10;
        double delta = 0.001;
        double gamma = 0;
        double pThreshold = 0.5;
        double grain = 0.01;
        int dim = 500;

        var q = new QuestState
        {
            UpdatePdf = true,
            WarnPdf = true,
            NormalizePdf = true,
            TGuess = tGuess,
            TGuessSd = tGuessSd,
            PThreshold = pThreshold,
            Beta = beta,
            Delta = delta,
            Gamma = gamma,
            Grain = grain,
            Dim = dim
        };

        QuestRecompute(q);

        int nTrials = 4;

        for (int trial = 1; trial <= nTrials; trial++)
        {
            Console.WriteLine($"Try new intensity -> {tGuess}");
            Console.WriteLine($"Try new intensity (unlogged) -> {(Math.Pow(10, tGuess) * 200)}");

            int response = ReadInt($"Trial {trial}, go(0)/no go(1) -> ");

            q.TrialData.Add(new TrialDatum
            {
                Response = response,
                UnloggedIntensity = (Math.Pow(10, tGuess) * 200) - 10,
                TGuess = tGuess
            });

            QuestUpdate(q, tGuess, response);
            tGuess = QuestMean(q);
            QuestRecompute(q);
        }

        q.FinalThreshold = (Math.Pow(10, tGuess) * 200) - 10;
        Console.WriteLine($"Estimated threshold = {q.FinalThreshold}");

        q.FinalSD = StandardDeviationSample(q.TrialData.Select(t => t.UnloggedIntensity).ToArray());
        double se = q.FinalSD / Math.Sqrt(40);
        q.CI95 = new[]
        {
            q.FinalThreshold - (1.96 * se),
            q.FinalThreshold + (1.96 * se)
        };

        Console.WriteLine($"95% CI = [{q.CI95[0]}, {q.CI95[1]}]");
    }

    private static int ReadInt(string prompt)
    {
        while (true)
        {
            Console.Write(prompt);
            string? raw = Console.ReadLine();
            if (int.TryParse(raw, NumberStyles.Integer, CultureInfo.InvariantCulture, out int value))
            {
                return value;
            }

            Console.WriteLine("Please enter a valid integer.");
        }
    }

    private static void QuestRecompute(QuestState q)
    {
        q.I = Range(-q.Dim / 2, q.Dim / 2).ToArray();
        q.X = q.I.Select(v => v * q.Grain).ToArray();
        q.Pdf = q.X.Select(x => Math.Exp(-0.5 * Math.Pow(x / q.TGuessSd, 2))).ToArray();
        NormalizeInPlace(q.Pdf);

        int[] i2 = Range(-q.Dim, q.Dim).ToArray();
        q.X2 = i2.Select(v => v * q.Grain).ToArray();
        q.P2 = q.X2.Select(x2 =>
            q.Delta * q.Gamma +
            (1 - q.Delta) * (1 - (1 - q.Gamma) * Math.Exp(-Math.Pow(10, q.Beta * x2)))
        ).ToArray();

        List<int> index = new();
        for (int i = 0; i < q.P2.Length - 1; i++)
        {
            if (q.P2[i + 1] != q.P2[i])
            {
                index.Add(i);
            }
        }

        double[] xp = index.Select(i => q.P2[i]).ToArray();
        double[] fp = index.Select(i => q.X2[i]).ToArray();
        q.XThreshold = Interp1(xp, fp, q.PThreshold);

        q.P2 = q.X2.Select(x2 =>
            q.Delta * q.Gamma +
            (1 - q.Delta) * (1 - (1 - q.Gamma) * Math.Exp(-Math.Pow(10, q.Beta * (x2 + q.XThreshold))))
        ).ToArray();

        q.S2 = new double[2, q.P2.Length];
        for (int i = 0; i < q.P2.Length; i++)
        {
            int flippedIndex = q.P2.Length - 1 - i;
            q.S2[0, i] = 1 - q.P2[flippedIndex];
            q.S2[1, i] = q.P2[flippedIndex];
        }

        if (q.Intensity == null || q.Response == null)
        {
            q.TrialCount = 0;
            q.Intensity = new double[10000];
            q.Response = new int[10000];
        }

        double pL = q.P2[0];
        double pH = q.P2[^1];
        double pE = pH * Math.Log(pH + double.Epsilon) - pL * Math.Log(pL + double.Epsilon)
                    + (1 - pH + double.Epsilon) * Math.Log(1 - pH + double.Epsilon)
                    - (1 - pL + double.Epsilon) * Math.Log(1 - pL + double.Epsilon);
        pE = 1 / (1 + Math.Exp(pE / (pL - pH)));
        q.QuantileOrder = (pE - pL) / (pH - pL);

        for (int k = 0; k < q.TrialCount; k++)
        {
            double inten = Math.Max(-1e10, Math.Min(1e10, q.Intensity[k]));
            int[] ii = q.I.Select(i => q.Pdf.Length + i - (int)Math.Round((inten - q.TGuess) / q.Grain)).ToArray();

            if (ii[0] < 1)
            {
                int shift = 1 - ii[0];
                ii = ii.Select(v => v + shift).ToArray();
            }

            if (ii[^1] > q.S2.GetLength(1))
            {
                int shift = q.S2.GetLength(1) - ii[^1];
                ii = ii.Select(v => v + shift).ToArray();
            }

            int row = q.Response[k];
            for (int n = 0; n < q.Pdf.Length; n++)
            {
                q.Pdf[n] *= q.S2[row, ii[n] - 1];
            }

            if (q.NormalizePdf && ((k + 1) % 100 == 0))
            {
                NormalizeInPlace(q.Pdf);
            }
        }

        if (q.NormalizePdf)
        {
            NormalizeInPlace(q.Pdf);
        }
    }

    private static void QuestUpdate(QuestState q, double intensity, int response)
    {
        if (q.UpdatePdf)
        {
            double inten = Math.Max(-1e10, Math.Min(1e10, intensity));
            int[] ii = q.I.Select(i => q.Pdf.Length + i - (int)Math.Round((inten - q.TGuess) / q.Grain)).ToArray();

            bool outOfRange = ii[0] < 1 || ii[^1] > q.S2.GetLength(1);
            if (outOfRange)
            {
                if (q.WarnPdf)
                {
                    double low = (1 - q.Pdf.Length - q.I[0]) * q.Grain + q.TGuess;
                    double high = (q.S2.GetLength(1) - q.Pdf.Length - q.I[^1]) * q.Grain + q.TGuess;
                    Console.WriteLine($"Warning: QuestUpdate intensity {intensity:F3} out of range {low:F2} to {high:F2}. Pdf will be inexact.");
                }

                if (ii[0] < 1)
                {
                    int shift = 1 - ii[0];
                    ii = ii.Select(v => v + shift).ToArray();
                }
                else
                {
                    int shift = q.S2.GetLength(1) - ii[^1];
                    ii = ii.Select(v => v + shift).ToArray();
                }
            }

            for (int n = 0; n < q.Pdf.Length; n++)
            {
                q.Pdf[n] *= q.S2[response, ii[n] - 1];
            }

            if (q.NormalizePdf)
            {
                NormalizeInPlace(q.Pdf);
            }
        }

        q.TrialCount++;
        if (q.TrialCount > q.Intensity!.Length)
        {
            Array.Resize(ref q.Intensity, q.Intensity.Length + 10000);
            Array.Resize(ref q.Response, q.Response!.Length + 10000);
        }

        q.Intensity[q.TrialCount - 1] = intensity;
        q.Response![q.TrialCount - 1] = response;
    }

    private static double QuestMean(QuestState q)
    {
        double numerator = 0;
        double denominator = 0;

        for (int i = 0; i < q.Pdf.Length; i++)
        {
            numerator += q.Pdf[i] * q.X[i];
            denominator += q.Pdf[i];
        }

        return q.TGuess + (numerator / denominator);
    }

    private static double StandardDeviationSample(double[] values)
    {
        if (values.Length <= 1)
        {
            return 0;
        }

        double mean = values.Average();
        double sumSquares = values.Select(v => Math.Pow(v - mean, 2)).Sum();
        return Math.Sqrt(sumSquares / (values.Length - 1));
    }

    private static IEnumerable<int> Range(int start, int endInclusive)
    {
        for (int v = start; v <= endInclusive; v++)
        {
            yield return v;
        }
    }

    private static double Interp1(double[] xp, double[] fp, double x)
    {
        if (xp.Length == 0)
        {
            throw new InvalidOperationException("Cannot interpolate from empty arrays.");
        }

        if (x <= xp[0])
        {
            return fp[0];
        }

        if (x >= xp[^1])
        {
            return fp[^1];
        }

        for (int i = 0; i < xp.Length - 1; i++)
        {
            if (x >= xp[i] && x <= xp[i + 1])
            {
                double t = (x - xp[i]) / (xp[i + 1] - xp[i]);
                return fp[i] + t * (fp[i + 1] - fp[i]);
            }
        }

        return fp[^1];
    }

    private static void NormalizeInPlace(double[] arr)
    {
        double s = arr.Sum();
        if (s == 0)
        {
            return;
        }

        for (int i = 0; i < arr.Length; i++)
        {
            arr[i] /= s;
        }
    }
}

public sealed class QuestState
{
    public bool UpdatePdf { get; set; }
    public bool WarnPdf { get; set; }
    public bool NormalizePdf { get; set; }

    public double TGuess { get; set; }
    public double TGuessSd { get; set; }
    public double PThreshold { get; set; }
    public double Beta { get; set; }
    public double Delta { get; set; }
    public double Gamma { get; set; }
    public double Grain { get; set; }
    public int Dim { get; set; }

    public int[] I { get; set; } = Array.Empty<int>();
    public double[] X { get; set; } = Array.Empty<double>();
    public double[] Pdf { get; set; } = Array.Empty<double>();
    public double[] X2 { get; set; } = Array.Empty<double>();
    public double[] P2 { get; set; } = Array.Empty<double>();
    public double XThreshold { get; set; }
    public double[,] S2 { get; set; } = new double[0, 0];

    public int TrialCount { get; set; }
    public double[]? Intensity { get; set; }
    public int[]? Response { get; set; }

    public double QuantileOrder { get; set; }
    public List<TrialDatum> TrialData { get; } = new();

    public double FinalThreshold { get; set; }
    public double FinalSD { get; set; }
    public double[] CI95 { get; set; } = Array.Empty<double>();
}

public sealed class TrialDatum
{
    public int Response { get; set; }
    public double UnloggedIntensity { get; set; }
    public double TGuess { get; set; }
}
