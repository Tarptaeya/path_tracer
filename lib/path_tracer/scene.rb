require 'parallel'

module PathTracer
  MAX_DEPTH = 10

  class Scene
    def initialize(width, height, camera, world)
      @width = width
      @height = height
      @camera = camera
      @world = world
    end

    def render(ns=1, file="output.ppm")
      puts "writing #{file}"

      data =
        Parallel.map(0...@height * @width) do |xy|
          x = xy % @width
          y = xy / @width
          col = Vector[0, 0, 0]
          (1..ns).each do |s1|
            (1..ns).each do |s2|
              i = (x + (s1 - Random.rand) / ns) / @width.to_f
              j = (y + (s2 - Random.rand) / ns) / @height.to_f
              ray = @camera.ray(i, j)
              col += color(ray)
            end
          end

          col /= (ns * ns).to_f

          percentage = (y * @width + x) * 100 / (@width * @height - 1)
          printf("\r[%-20s] %d%%", "=" * (percentage / 5), percentage)

          col
        end
      puts

      File.open(file, "w") do |f|
        f << "P3\n"
        f << "#{@width} #{@height}\n"
        f << "255\n"
        (0...@height).reverse_each do |y|
          (0...@width).each do |x|
            col = data[y * @width + x]
            r = (255.99 * col[0] ** 0.5).truncate
            g = (255.99 * col[1] ** 0.5).truncate
            b = (255.99 * col[2] ** 0.5).truncate
            f << "#{r} #{g} #{b}\n"
          end
        end
      end
    end

    private

    def color(ray, depth=0)
      if rec = @world.hit(ray, 0.001, Float::INFINITY)
        material = rec.material
        emitted = material.emitted(rec.u, rec.v, rec.p)
        if depth < MAX_DEPTH && scatter = material.scatter(ray, rec)
          attenuation, scattered = scatter
          emitted + attenuation * color(scattered, depth + 1)
        else
          emitted
        end
      else
        Vector[0, 0, 0]
      end
    end
  end
end
